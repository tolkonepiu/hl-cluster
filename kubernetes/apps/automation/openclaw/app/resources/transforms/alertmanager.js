export default async function transform(payload) {
  const alerts = Array.isArray(payload?.alerts) ? payload.alerts : [];
  const firing = alerts.filter((a) => a.status === "firing");
  const resolved = alerts.filter((a) => a.status === "resolved");
  const common = payload?.commonLabels || {};

  const clip = (s, n = 400) =>
    typeof s === "string" && s.length > n ? `${s.slice(0, n)}…` : s;

  const lines = [
    "Alertmanager webhook received.",
    `Status: ${payload?.status ?? "unknown"}`,
    `Receiver: ${payload?.receiver ?? "-"}`,
    `Group key: ${payload?.groupKey ?? "-"}`,
    `Firing: ${firing.length}, Resolved: ${resolved.length}`,
    `Common alertname: ${common.alertname ?? "-"}`,
    `Common severity: ${common.severity ?? "-"}`,
    "",
  ];

  for (const a of alerts.slice(0, 10)) {
    const labels = a.labels || {};
    const ann = a.annotations || {};
    lines.push(
      `- [${a.status}] ${labels.alertname ?? "unknown"} ` +
        `(severity=${labels.severity ?? "-"}, namespace=${labels.namespace ?? "-"})`,
    );
    if (ann.summary) lines.push(`  summary: ${clip(ann.summary, 200)}`);
    if (ann.description)
      lines.push(`  description: ${clip(ann.description, 400)}`);
  }

  if (alerts.length > 10) {
    lines.push("", `...and ${alerts.length - 10} more alerts`);
  }

  return {
    name: "Alertmanager",
    sessionKey: `hook:alertmanager:${payload?.groupKey ?? payload?.receiver ?? "default"}`,
    message: lines.join("\n"),
  };
}
