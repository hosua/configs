import Database from "better-sqlite3";
import type { CoinSummary } from "./types";

type SortBy = "rank" | "rate" | "volume" | "cap";

const SORT_COLUMNS: Record<SortBy, string> = {
  rank: "c.rank ASC",
  rate: "s.rate DESC",
  volume: "s.volume DESC",
  cap: "s.cap DESC",
};

export function listCoins(
  db: Database.Database,
  opts: { limit?: number; sortBy?: SortBy } = {}
): CoinSummary[] {
  const { limit = 100, sortBy = "rank" } = opts;
  const orderClause = SORT_COLUMNS[sortBy] ?? SORT_COLUMNS.rank;

  const query = db.prepare<[number], CoinSummary>(`
    SELECT
      c.code, c.name, c.symbol, c.rank, c.color, c.png32,
      c.all_time_high_usd, c.max_supply,
      s.rate, s.volume, s.cap, s.ts,
      s.delta_hour, s.delta_day, s.delta_week,
      s.delta_month, s.delta_quarter, s.delta_year
    FROM coins c
    LEFT JOIN snapshots s
      ON s.coin_code = c.code
      AND s.ts = (SELECT MAX(ts) FROM snapshots WHERE coin_code = c.code)
    ORDER BY ${orderClause}
    LIMIT ?
  `);

  return query.all(limit);
}

export function getCoin(
  db: Database.Database,
  code: string
): CoinSummary | undefined {
  const query = db.prepare<[string], CoinSummary>(`
    SELECT
      c.code, c.name, c.symbol, c.rank, c.color, c.png32,
      c.all_time_high_usd, c.max_supply,
      s.rate, s.volume, s.cap, s.ts,
      s.delta_hour, s.delta_day, s.delta_week,
      s.delta_month, s.delta_quarter, s.delta_year
    FROM coins c
    LEFT JOIN snapshots s
      ON s.coin_code = c.code
      AND s.ts = (SELECT MAX(ts) FROM snapshots WHERE coin_code = c.code)
    WHERE c.code = ?
  `);

  return query.get(code);
}
