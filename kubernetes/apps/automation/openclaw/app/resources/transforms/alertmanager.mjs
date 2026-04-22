export default async function transform(input) {
  const payload = input?.payload ?? {};

  const alerts = Array.isArray(payload?.alerts) ? payload.alerts : [];
  const firing = alerts.filter((alert) => alert.status === "firing");
  const resolved = alerts.filter((alert) => alert.status === "resolved");
  const commonLabels = payload?.commonLabels || {};

  const clip = (s, n = 400) =>
    typeof s === "string" && s.length > n ? `${s.slice(0, n)}…` : s;

  const lines = [
    "Alertmanager webhook received.",
    `Status: ${payload?.status ?? "unknown"}`,
    `Receiver: ${payload?.receiver ?? "-"}`,
    `Group key: ${payload?.groupKey ?? "-"}`,
    `Firing: ${firing.length}, Resolved: ${resolved.length}`,
    `Common alertname: ${commonLabels.alertname ?? "-"}`,
    `Common severity: ${commonLabels.severity ?? "-"}`,
    "",
  ];

  for (const alert of alerts.slice(0, 10)) {
    const labels = alert.labels || {};
    const annotations = alert.annotations || {};
    lines.push(
      `- [${alert.status}] ${labels.alertname ?? "unknown"} ` +
        `(severity=${labels.severity ?? "-"}, namespace=${labels.namespace ?? "-"})`,
    );
    if (annotations.summary) {
      lines.push(`  summary: ${clip(annotations.summary, 200)}`);
    }
    if (annotations.description) {
      lines.push(`  description: ${clip(annotations.description, 400)}`);
    }
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
