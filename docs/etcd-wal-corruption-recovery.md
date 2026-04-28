# Recovering a k3s Embedded-Etcd Node After WAL Corruption

## Overview

Use this runbook when a k3s server node that participates in embedded etcd fails
to start because its local etcd data is corrupted. A common symptom is a
`walpb: crc mismatch` error in the `k3s` journal, followed by a restart loop and
the node becoming `NotReady`.

This procedure assumes the rest of the control-plane quorum is still healthy. If
quorum is already lost, do not use this guide. At that point, switch to a
cluster restore procedure from a known-good etcd snapshot.

## When This Runbook Applies

This runbook is appropriate when all of the following are true:

- The affected node is a k3s server with embedded etcd enabled.
- At least two other etcd members are still healthy enough to keep quorum.
- The affected node is failing locally, not the whole cluster.
- You can reach the affected node over SSH.
- You can run `kubectl` against the surviving control-plane nodes.

## Typical Symptoms

Check the failed node first:

```bash
journalctl -u k3s -n 200 --no-pager
```

Typical failure signs include:

- `walpb: crc mismatch`
- `failed to start cluster`
- `connection refused` on `127.0.0.1:2379`
- repeated `k3s.service` restart attempts in systemd

From a healthy control-plane node, the Kubernetes side usually looks like this:

```bash
kubectl get nodes -o wide
```

Expected symptoms:

- the failed node is `NotReady`
- the node may already be `SchedulingDisabled`
- workloads previously running there start moving elsewhere

## Safety Checks Before Recovery

Do not touch the failed node until you verify that quorum still exists.

1. Confirm that the other control-plane nodes are healthy.
2. Confirm that the cluster still responds to `kubectl`.
3. Confirm that a recent etcd snapshot exists on a healthy node.

Examples:

```bash
kubectl get nodes -o wide
```

```bash
k3s etcd-snapshot ls
```

If only one voting member remains healthy, stop here. A remove-and-rejoin flow
is no longer the safest path.

## Recovery Strategy

When quorum is intact, the safest recovery is usually:

1. Isolate the bad node.
2. Back up its corrupted local etcd directory.
3. Remove its etcd membership from the healthy cluster.
4. Start the node again with an empty local etcd directory.
5. Let k3s rejoin it as a fresh member.

The important idea is that you do not try to repair the broken WAL in place. You
replace the failed member cleanly instead.

## Recovery Procedure

### Step 1 - Cordon the affected node

If the node is still schedulable, cordon it first:

```bash
kubectl cordon <failed-node-name>
```

Verify:

```bash
kubectl get node <failed-node-name>
```

### Step 2 - Stop k3s on the affected node

On the failed node:

```bash
systemctl stop k3s
systemctl is-active k3s
```

Expected result: `inactive`.

This prevents the failed member from continuously retrying startup while you are
cleaning up cluster membership.

### Step 3 - Back up the local etcd directory

Do not delete the broken data immediately. Move it aside first so you keep a
forensic copy.

On the failed node:

```bash
ts=$(date +%Y%m%d-%H%M%S)
mv /var/lib/rancher/k3s/server/db/etcd \
  /var/lib/rancher/k3s/server/db/etcd.bak-$ts
```

Verify that the original `etcd` directory is gone:

```bash
ls -ld /var/lib/rancher/k3s/server/db \
  /var/lib/rancher/k3s/server/db/etcd.bak-*
```

Keep this backup until the node is fully healthy again.

### Step 4 - Remove the failed member from the healthy cluster

Run this step from a healthy control-plane node, not from the failed node.

K3s supports native etcd member removal through a node annotation:

```bash
kubectl annotate node <failed-node-name> \
  etcd.k3s.cattle.io/remove=true --overwrite
```

Watch for the membership change:

```bash
kubectl get node <failed-node-name> -o yaml
```

Signs that removal has been processed:

- `etcd.k3s.cattle.io/removed-node-name` appears
- the `EtcdIsVoter` condition becomes `False`
- the message says the node is not a member of the etcd cluster

If you also have access to healthy node logs, you should see a message similar
to `Removing etcd member from cluster due to remove annotation`.

### Step 5 - Start k3s on the failed node again

Once the member is removed and the local etcd directory has been cleared, start
the node again:

```bash
systemctl start k3s
systemctl is-active k3s
```

Expected result: `active`.

Then inspect the logs:

```bash
journalctl -u k3s --since '10 minutes ago' --no-pager
```

Healthy recovery usually looks like this:

- k3s adds the node back to the cluster
- etcd starts as a learner
- the node receives a snapshot from an existing member
- the learner is promoted to a voter
- the local API server starts normally

Look for messages such as:

- `Adding member ... to etcd cluster`
- `received and saved database snapshot`
- `promote member`
- `ETCD server is now running`
- `Kube API server is now running`

### Step 6 - Verify the node has fully rejoined

Check the Kubernetes node conditions first:

```bash
kubectl get node <failed-node-name> -o jsonpath='{
.status.conditions[?(@.type=="Ready")].status}{"\n"}{
.status.conditions[?(@.type=="EtcdIsVoter")].status}{"\n"}{
.spec.unschedulable}{"\n"}'
```

Expected output:

- `True` for `Ready`
- `True` for `EtcdIsVoter`
- `true` or `false` for `unschedulable`, depending on whether you uncordoned it

Then inspect the whole cluster:

```bash
kubectl get nodes -o wide
```

The recovered node should now appear as `Ready` again.

### Step 7 - Uncordon the node

When the node is healthy, return it to scheduling:

```bash
kubectl uncordon <failed-node-name>
```

Verify:

```bash
kubectl get nodes -o wide
```

### Step 8 - Verify cluster workloads and GitOps

If the cluster uses Flux, check that reconciliation is healthy again:

```bash
kubectl get kustomizations,helmreleases -n flux-system
```

It is also worth checking pods on the recovered node:

```bash
kubectl get pods -A -o wide \
  --field-selector spec.nodeName=<failed-node-name>
```

System workloads such as CNI, kube-vip, or node exporters should begin running
there again.

## What This Procedure Does Not Do

This runbook does not:

- repair the corrupted WAL in place
- restore the whole cluster from snapshot
- rebuild the entire control plane

Those are different recovery paths with a larger blast radius.

## When to Abort This Procedure

Stop and switch strategies if any of the following happens:

- another etcd member becomes unhealthy while you are working
- `kubectl` stops responding from the healthy nodes
- the failed node cannot reach the remaining control-plane nodes
- the node starts, but never progresses past learner status

At that point, gather logs and decide whether the cluster now needs snapshot
restore or a deeper network or storage investigation.

## Cleanup After Successful Recovery

After the node has been stable for a while, you can remove the local backup of
the corrupted etcd directory.

On the recovered node:

```bash
rm -rf /var/lib/rancher/k3s/server/db/etcd.bak-<timestamp>
```

Do not delete it immediately if you still want material for a postmortem.

## Recommended Follow-Up

After recovery, capture the incident while it is fresh:

- record the exact error from `journalctl`
- note which node failed and which nodes preserved quorum
- note the snapshot age on the healthy nodes
- record how long the node stayed unavailable
- review possible storage, power, or upgrade interruption causes

If this happened during an automated upgrade, also review whether the upgrade
controller should stagger control-plane changes more conservatively.

## References

- [k3s documentation](https://docs.k3s.io/)
- [k3s embedded etcd documentation](https://docs.k3s.io/datastore/ha-embedded)
- [k3s issue on member replacement](https://github.com/k3s-io/k3s/issues/13623)
- [k3s issue on purging failed member state](https://github.com/k3s-io/k3s/issues/8217)
