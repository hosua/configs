const NOW = Math.floor(Date.now() / 1000);

export function parseTimeArg(arg: string): number {
  if (/^\d+$/.test(arg)) return Number(arg);

  const relative = arg.match(/^(\d+(?:\.\d+)?)(h|d|w|m)$/i);
  if (relative) {
    const n = parseFloat(relative[1]);
    const unit = relative[2].toLowerCase();
    const multipliers: Record<string, number> = { h: 3600, d: 86400, w: 604800, m: 2592000 };
    return NOW - Math.round(n * multipliers[unit]);
  }

  const ts = Math.floor(new Date(arg).getTime() / 1000);
  if (isNaN(ts)) throw new Error(`Cannot parse time argument: ${arg}`);
  return ts;
}

export function fmtDate(ts: number): string {
  return new Date(ts * 1000).toISOString().replace("T", " ").slice(0, 19);
}

export function fmtNum(n: number | null, decimals = 2): string {
  if (n === null || n === undefined) return "—";
  if (Math.abs(n) >= 1e12) return (n / 1e12).toFixed(2) + "T";
  if (Math.abs(n) >= 1e9) return (n / 1e9).toFixed(2) + "B";
  if (Math.abs(n) >= 1e6) return (n / 1e6).toFixed(2) + "M";
  return n.toFixed(decimals);
}

export function fmtDelta(d: number | null): string {
  if (d === null || d === undefined) return "—";
  const pct = ((d - 1) * 100).toFixed(2);
  return d >= 1 ? `+${pct}%` : `${pct}%`;
}

export function formatTable(headers: string[], rows: string[][]): string {
  const widths = headers.map((h, i) =>
    Math.max(h.length, ...rows.map((r) => (r[i] ?? "").length))
  );

  const pad = (s: string, w: number) => s.padEnd(w);
  const divider = widths.map((w) => "─".repeat(w)).join("─┼─");
  const header = headers.map((h, i) => pad(h, widths[i])).join(" │ ");

  const lines: string[] = [header, divider];
  for (const row of rows) {
    lines.push(row.map((cell, i) => pad(cell ?? "", widths[i])).join(" │ "));
  }

  return lines.join("\n");
}
