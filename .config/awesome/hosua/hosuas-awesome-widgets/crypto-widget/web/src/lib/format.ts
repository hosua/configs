export function formatRate(rate: number): string {
  if (rate >= 1000) {
    return rate.toLocaleString("en-US", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
  }
  if (rate >= 1) {
    return rate.toLocaleString("en-US", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 4,
    });
  }
  return rate.toLocaleString("en-US", {
    minimumFractionDigits: 4,
    maximumFractionDigits: 8,
  });
}

export function formatDeltaPercent(multiplier: number): string {
  const pct = (multiplier - 1) * 100;
  return `${pct >= 0 ? "+" : ""}${pct.toFixed(2)}%`;
}

export function deltaIsPositive(multiplier: number): boolean {
  return multiplier > 1;
}

export function deltaIsNegative(multiplier: number): boolean {
  return multiplier < 1;
}

export function stripUnderscores(code: string): string {
  return code.replace(/_/g, "");
}

export function formatVolume(vol: number): string {
  if (vol >= 1e12) return `$${(vol / 1e12).toFixed(2)}T`;
  if (vol >= 1e9) return `$${(vol / 1e9).toFixed(2)}B`;
  if (vol >= 1e6) return `$${(vol / 1e6).toFixed(2)}M`;
  return `$${vol.toLocaleString()}`;
}
