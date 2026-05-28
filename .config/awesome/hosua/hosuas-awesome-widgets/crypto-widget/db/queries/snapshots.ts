import Database from "better-sqlite3";
import type { SnapshotRow, GainerLoser, SupplyPoint, TimeRange, DeltaPeriod, ComparePoint } from "./types";

const DELTA_COLS: Record<DeltaPeriod, string> = {
  hour: "delta_hour",
  day: "delta_day",
  week: "delta_week",
  month: "delta_month",
  quarter: "delta_quarter",
  year: "delta_year",
};

function timeFilter(range?: TimeRange): { clause: string; params: number[] } {
  if (!range?.from && !range?.to) return { clause: "", params: [] };
  const parts: string[] = [];
  const params: number[] = [];
  if (range.from) { parts.push("ts >= ?"); params.push(range.from); }
  if (range.to) { parts.push("ts <= ?"); params.push(range.to); }
  return { clause: " AND " + parts.join(" AND "), params };
}

export function getRateHistory(
  db: Database.Database,
  code: string,
  range?: TimeRange
): SnapshotRow[] {
  const { clause, params } = timeFilter(range);
  const query = db.prepare<unknown[], SnapshotRow>(
    `SELECT coin_code, ts, rate, volume, cap,
            delta_hour, delta_day, delta_week, delta_month, delta_quarter, delta_year
     FROM snapshots WHERE coin_code = ?${clause} ORDER BY ts ASC`
  );
  return query.all(code, ...params);
}

export function compareCoins(
  db: Database.Database,
  codes: readonly string[],
  range?: TimeRange
): ComparePoint[] {
  if (codes.length === 0) return [];

  const { clause, params } = timeFilter(range);
  const placeholders = codes.map(() => "?").join(", ");

  // Align to 60s buckets to handle dedup-induced timestamp skew
  const rows = db.prepare<unknown[], { coin_code: string; bucket: number; rate: number }>(
    `SELECT coin_code, (ts / 60) * 60 AS bucket, AVG(rate) AS rate
     FROM snapshots
     WHERE coin_code IN (${placeholders})${clause}
     GROUP BY coin_code, bucket
     ORDER BY bucket ASC`
  ).all(...codes, ...params);

  const byBucket = new Map<number, ComparePoint>();
  for (const row of rows) {
    if (!byBucket.has(row.bucket)) byBucket.set(row.bucket, { bucket: row.bucket });
    byBucket.get(row.bucket)![row.coin_code] = row.rate;
  }

  return Array.from(byBucket.values()).sort((a, b) => a.bucket - b.bucket);
}

export function getTopMovers(
  db: Database.Database,
  opts: { period: DeltaPeriod; direction: "gainers" | "losers"; limit?: number }
): GainerLoser[] {
  const { period, direction, limit = 10 } = opts;
  const col = DELTA_COLS[period];
  const order = direction === "gainers" ? "DESC" : "ASC";

  return db.prepare<[number], GainerLoser>(
    `SELECT c.code, c.name, c.rank, s.rate, s.${col} AS delta, '${period}' AS period
     FROM coins c
     JOIN snapshots s
       ON s.coin_code = c.code
       AND s.ts = (SELECT MAX(ts) FROM snapshots WHERE coin_code = c.code)
     WHERE s.${col} IS NOT NULL
     ORDER BY s.${col} ${order}
     LIMIT ?`
  ).all(limit);
}

export function getSupplyHistory(
  db: Database.Database,
  code: string,
  range?: TimeRange
): SupplyPoint[] {
  const { clause, params } = timeFilter(range);
  return db.prepare<unknown[], SupplyPoint>(
    `SELECT coin_code, ts, circulating_supply, total_supply
     FROM supply_snapshots WHERE coin_code = ?${clause} ORDER BY ts ASC`
  ).all(code, ...params);
}
