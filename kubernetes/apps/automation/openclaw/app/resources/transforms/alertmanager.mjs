export default async function transform(input) {
  const payload = input?.payload ?? {};
  const alerts = Array.isArray(payload?.alerts) ? payload.alerts : [];

  const status = String(payload?.status ?? "unknown").toUpperCase();
  const alertname = payload?.commonLabels?.alertname ?? "Alertmanager";
  const firingCount = alerts.filter((a) => a.status === "firing").length;

  const title =
    status === "FIRING"
      ? `**[${status}:${firingCount}] ${alertname}**`
      : `**[${status}] ${alertname}**`;

  const clip = (s, n = 1200) =>
    typeof s === "string" && s.length > n ? `${s.slice(0, n)}…` : s;

  const pickAlertText = (alert) => {
    const annotations = alert?.annotations || {};
    return (
      annotations.description ||
      annotations.summary ||
      annotations.message ||
      "Alert description not available"
    );
  };

  const formatLabels = (labels) => {
    const entries = Object.entries(labels || {})
      .filter(
        ([, value]) => value !== undefined && value !== null && value !== "",
      )
      .sort(([a], [b]) => a.localeCompare(b));

    if (entries.length === 0) return "";

    return entries.map(([key, value]) => `- **${key}:** ${value}`).join("\n");
  };

  const blocks = alerts.map((alert) => {
    const text = clip(pickAlertText(alert), 1200);
    const labelsText = formatLabels(alert?.labels);

    return labelsText ? `${text}\n\n${labelsText}` : text;
  });

  return {
    name: "Alertmanager",
    sessionKey: "hook:alertmanager",
    message: [title, "", ...blocks].join("\n\n"),
  };
}
