import Database from "better-sqlite3";
import { existsSync, readFileSync, statSync } from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "../..");

const dbPath = process.env.DB_PATH
  ? path.resolve(process.env.DB_PATH)
  : path.join(projectRoot, "crypto.db");

const latestJsonPath = process.env.DATA_PATH
  ? path.resolve(process.env.DATA_PATH)
  : path.join(projectRoot, "data", "latest.json");

// Fall back to DB only if the file is more than 24h old (widget clearly not running)
const LATEST_JSON_MAX_AGE = 86400;

let db: Database.Database | null = null;

function getDb(): Database.Database {
  if (!db) {
    db = new Database(dbPath, { readonly: true });
  }
  return db;
}

export interface CoinRow {
  code: string;
  name: string;
  symbol: string | null;
  rank: number | null;
  color: string | null;
  png32: string | null;
  all_time_high_usd: number | null;
  max_supply: number | null;
  rate: number | null;
  volume: number | null;
  cap: number | null;
  ts: number | null;
  delta_hour: number | null;
  delta_day: number | null;
  delta_week: number | null;
  delta_month: number | null;
  delta_quarter: number | null;
  delta_year: number | null;
}

interface LiveCoinEntry {
  code: string;
  name: string;
  symbol?: string | null;
  rank?: number | null;
  color?: string | null;
  png32?: string | null;
  allTimeHighUSD?: number | null;
  maxSupply?: number | null;
  circulatingSupply?: number | null;
  totalSupply?: number | null;
  rate: number;
  volume?: number | null;
  cap?: number | null;
  delta?: {
    hour?: number | null;
    day?: number | null;
    week?: number | null;
    month?: number | null;
    quarter?: number | null;
    year?: number | null;
  } | null;
}

function fromLiveJson(coins: LiveCoinEntry[]): CoinRow[] {
  const now = Math.floor(Date.now() / 1000);
  return coins.map((c) => ({
    code: c.code,
    name: c.name,
    symbol: c.symbol ?? null,
    rank: c.rank ?? null,
    color: c.color ?? null,
    png32: c.png32 ?? null,
    all_time_high_usd: c.allTimeHighUSD ?? null,
    max_supply: c.maxSupply ?? null,
    rate: c.rate,
    volume: c.volume ?? null,
    cap: c.cap ?? null,
    ts: now,
    delta_hour: c.delta?.hour ?? null,
    delta_day: c.delta?.day ?? null,
    delta_week: c.delta?.week ?? null,
    delta_month: c.delta?.month ?? null,
    delta_quarter: c.delta?.quarter ?? null,
    delta_year: c.delta?.year ?? null,
  }));
}

function readLatestJson(): CoinRow[] | null {
  if (!existsSync(latestJsonPath)) return null;

  const age = Math.floor(
    (Date.now() - statSync(latestJsonPath).mtimeMs) / 1000,
  );
  if (age > LATEST_JSON_MAX_AGE) return null;

  try {
    const coins: LiveCoinEntry[] = JSON.parse(
      readFileSync(latestJsonPath, "utf8"),
    );
    return fromLiveJson(coins);
  } catch {
    return null;
  }
}

function readFromDb(limit: number): CoinRow[] {
  const query = getDb().prepare<[number], CoinRow>(`
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
    ORDER BY c.rank ASC
    LIMIT ?
  `);
  return query.all(limit);
}

export function getCoins(limit = 100): CoinRow[] {
  // Prefer live data from widget's latest.json (updated every 20s)
  const live = readLatestJson();
  if (live) return live.slice(0, limit);
  return readFromDb(limit);
}

export interface HistoryPoint {
  ts: number;
  rate: number;
}

export function getCoinHistory(code: string, days = 3): HistoryPoint[] {
  const since = Math.floor(Date.now() / 1000) - days * 86400;
  const query = getDb().prepare<[string, number], HistoryPoint>(`
    SELECT ts, rate FROM snapshots
    WHERE coin_code = ? AND ts >= ?
    ORDER BY ts ASC
  `);
  return query.all(code, since);
}
