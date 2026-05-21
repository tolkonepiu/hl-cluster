<!-- markdownlint-disable -->
<h1 align="center">
	<img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1faa9/512.gif" width="150" alt="Logo"/><br/>
	<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
	My HomeLab Cluster
</picture>
	<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
</h1>

<p align="center">
  ... managed with Flux, Renovate, Hermes Agent, and GitHub Actions  <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="400" />
</p>

<div align="center">

[![k3s](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fk3s_version&style=for-the-badge&logo=k3s&logoColor=white&color=cba6f7&label=k3s&labelColor=45475a)](https://k3s.io/)&nbsp;&nbsp;
[![Flux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fflux_version&style=for-the-badge&logo=flux&logoColor=white&color=cba6f7&label=Flux&labelColor=45475a)](https://fluxcd.io)&nbsp;&nbsp;
[![Linux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Flinux_version&style=for-the-badge&logo=linux&logoColor=white&color=cba6f7&label=Linux&labelColor=45475a)](https://kernel.org/)

</div>

<div align="center">

![Home Network](https://img.shields.io/uptimerobot/status/m802337331-b8cce90b210a48a9aca3b6e0?style=for-the-badge&label=Home%20Network&labelColor=45475a&up_color=a6e3a1&down_color=f38ba8)&nbsp;&nbsp;
![Cluster Status](https://img.shields.io/uptimerobot/status/m801091926-010c803363d731fd23336aee?style=for-the-badge&label=Cluster%20Status&labelColor=45475a&up_color=a6e3a1&down_color=f38ba8)&nbsp;&nbsp;
![Alertmanager](https://img.shields.io/uptimerobot/status/m801095660-6ff37a7d0c145febc4bb2cf4?style=for-the-badge&label=Alertmanager&labelColor=45475a&up_color=a6e3a1&down_color=f38ba8)&nbsp;&nbsp;

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_age_days&style=flat-square&label=Age&labelColor=45475a)](https://github.com/kashalls/kromgo/)&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_uptime_days&style=flat-square&label=Uptime&labelColor=45475a)](https://github.com/kashalls/kromgo/)&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_node_count&style=flat-square&label=Nodes&labelColor=45475a)](https://github.com/kashalls/kromgo/)&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_pod_count&style=flat-square&label=Pods&labelColor=45475a)](https://github.com/kashalls/kromgo/)&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_cpu_usage&style=flat-square&label=CPU&labelColor=45475a)](https://github.com/kashalls/kromgo/)&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_memory_usage&style=flat-square&label=Memory&labelColor=45475a)](https://github.com/kashalls/kromgo/)&nbsp;
[![Alerts](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.popov.wtf%2Fcluster_alert_count&style=flat-square&label=Alerts&labelColor=45475a)](https://github.com/kashalls/kromgo)

</div>
<!-- markdownlint-enable -->

## Overview

This repository is my home Kubernetes cluster in a declarative state.
[Flux](https://github.com/fluxcd/flux2) watches the [kubernetes](./kubernetes/)
folder and will make the changes to the cluster based on the YAML manifests.

The cluster runs on [k3s](https://k3s.io/) and consists of nodes based on
[Rock Pi 4B](https://radxa.com/products/rock4/4b/) single-board computers, each
equipped with 1TB NVME storage. Power to the boards is supplied through
[ROCKPI 23W PoE HAT](https://wiki.radxa.com/ROCKPI_23W_PoE_HAT) modules.

Although [Talos Linux](https://www.talos.dev/) was initially planned as the
operating system (which has
[official support for Rock Pi 4B](https://www.talos.dev/v1.6/talos-guides/install/single-board-computers/rockpi_4/)),
it has
[issues with NVME storage](https://github.com/siderolabs/sbc-rockchip/issues/65)
on this hardware platform, so k3s was chosen instead.

<!-- markdownlint-disable -->

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a1/512.gif" alt="💡" width="16" height="16"> Core Components

<!-- markdownlint-enable -->

Core components that form the foundation of the cluster:

- [cilium/cilium](https://github.com/cilium/cilium): Kubernetes CNI.
- [envoyproxy/envoy](https://github.com/envoyproxy/gateway): Kubernetes-based
  application gateway using
  [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL
  certificates for services in my Kubernetes cluster.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns):
  Automatically manages DNS records from my cluster in CloudFlare.
- [rancher/system-upgrade-controller](https://github.com/rancher/system-upgrade-controller):
  Handles k3s upgrades automatically.
- [kubereboot/kured](https://github.com/kubereboot/kured): Kubernetes reboot
  daemon that performs safe automatic node reboots when needed.

<!-- markdownlint-disable -->

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6a8/512.gif" alt="🚨" width="16" height="16"> Observability

<!-- markdownlint-enable -->

For observability and monitoring of the cluster the following software is used:

- [grafana/grafana](https://github.com/grafana/grafana): Data visualization
  platform.
- [prometheus/alertmanager](https://github.com/prometheus/alertmanager): Handles
  processing and sending alerts.
- [pushover](https://pushover.net): Handles receiving alerts on my devices.
- [VictoriaMetrics/VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics):
  Time series database, drop-in replacement for Prometheus.

<!-- markdownlint-disable -->

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16"> Automation

<!-- markdownlint-enable -->

- [Github Actions](https://docs.github.com/en/actions) for checking code
  formatting and running periodic jobs
- [Renovate](https://github.com/renovatebot/renovate) keeps the application
  charts and container images up-to-date
- [Hermes Agent](https://github.com/nousresearch/hermes-agent) acts as an
  operator assistant for diagnostics, troubleshooting, and Git-backed
  maintenance workflows

<!-- markdownlint-disable -->

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/270f_fe0f/512.gif" alt="✏" width="16" height="16"> License

<!-- markdownlint-enable -->

See [LICENSE](./LICENSE)
