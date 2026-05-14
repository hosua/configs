import "./env-loader";
import Database from "better-sqlite3";
import { readFileSync } from "fs";
import { resolve } from "path";
import type { CoinEntry } from "./types";

const dbPath = resolve(__dirname, process.env.DB_PATH ?? "../crypto.db");
const dataPath = resolve(__dirname, "../data/latest.json");
const epsilon = parseFloat(process.env.DEDUP_EPSILON ?? "0");

const db = new Database(dbPath);
db.pragma("journal_mode = WAL");
db.pragma("foreign_keys = ON");

const upsertCoin = db.prepare<[string, string, string | null, number | null, number | null, string | null, string | null, number | null, number | null, number]>(`
  INSERT INTO coins (code, name, symbol, rank, age, color, png32, all_time_high_usd, max_supply, updated_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ON CONFLICT(code) DO UPDATE SET
    name              = excluded.name,
    symbol            = excluded.symbol,
    rank              = excluded.rank,
    age               = excluded.age,
    color             = excluded.color,
    png32             = excluded.png32,
    all_time_high_usd = excluded.all_time_high_usd,
    max_supply        = excluded.max_supply,
    updated_at        = excluded.updated_at
`);

const getLastRate = db.prepare<[string], { rate: number }>(
  `SELECT rate FROM snapshots WHERE coin_code = ? ORDER BY ts DESC LIMIT 1`
);

const insertSnapshot = db.prepare<[string, number, number, number | null, number | null, number | null, number | null, number | null, number | null, number | null, number | null]>(`
  INSERT OR IGNORE INTO snapshots
    (coin_code, ts, rate, volume, cap, delta_hour, delta_day, delta_week, delta_month, delta_quarter, delta_year)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`);

const getLastSupply = db.prepare<[string], { circulating_supply: number | null; total_supply: number | null }>(
  `SELECT circulating_supply, total_supply FROM supply_snapshots WHERE coin_code = ? ORDER BY ts DESC LIMIT 1`
);

const insertSupply = db.prepare<[string, number, number | null, number | null]>(`
  INSERT OR IGNORE INTO supply_snapshots (coin_code, ts, circulating_supply, total_supply)
  VALUES (?, ?, ?, ?)
`);

function rateChanged(newRate: number, lastRate: number): boolean {
  if (epsilon === 0) return newRate !== lastRate;
  return Math.abs(newRate - lastRate) / lastRate > epsilon;
}

const ingestAll = db.transaction((coins: CoinEntry[]) => {
  const now = Math.floor(Date.now() / 1000);
  let snapshotCount = 0;
  let supplyCount = 0;

  for (const coin of coins) {
    upsertCoin.run(
      coin.code,
      coin.name,
      coin.symbol ?? null,
      coin.rank ?? null,
      coin.age ?? null,
      coin.color ?? null,
      coin.png32 ?? null,
      coin.allTimeHighUSD ?? null,
      coin.maxSupply ?? null,
      now
    );

    const last = getLastRate.get(coin.code);
    if (!last || rateChanged(coin.rate, last.rate)) {
      insertSnapshot.run(
        coin.code,
        now,
        coin.rate,
        coin.volume ?? null,
        coin.cap ?? null,
        coin.delta?.hour ?? null,
        coin.delta?.day ?? null,
        coin.delta?.week ?? null,
        coin.delta?.month ?? null,
        coin.delta?.quarter ?? null,
        coin.delta?.year ?? null
      );
      snapshotCount++;
    }

    const lastSup = getLastSupply.get(coin.code);
    const circChanged = (lastSup?.circulating_supply ?? null) !== (coin.circulatingSupply ?? null);
    const totalChanged = (lastSup?.total_supply ?? null) !== (coin.totalSupply ?? null);
    if (!lastSup || circChanged || totalChanged) {
      insertSupply.run(
        coin.code,
        now,
        coin.circulatingSupply ?? null,
        coin.totalSupply ?? null
      );
      supplyCount++;
    }
  }

  return { snapshotCount, supplyCount };
});

try {
  const raw = readFileSync(dataPath, "utf8");
  const coins: CoinEntry[] = JSON.parse(raw);
  const { snapshotCount, supplyCount } = ingestAll(coins);
  process.stdout.write(`Ingested ${snapshotCount} snapshots, ${supplyCount} supply rows (${coins.length} coins total)\n`);
} catch (err) {
  process.stderr.write(`Ingest error: ${(err as Error).message}\n`);
  process.exit(1);
} finally {
  db.close();
}
