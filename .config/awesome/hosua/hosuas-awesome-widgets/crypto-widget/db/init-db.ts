import "./env-loader";
import Database from "better-sqlite3";
import { resolve } from "path";

const dbPath = resolve(__dirname, process.env.DB_PATH ?? "../crypto.db");
const db = new Database(dbPath);

db.pragma("journal_mode = WAL");
db.pragma("foreign_keys = ON");

db.exec(`
  CREATE TABLE IF NOT EXISTS coins (
    code              TEXT    PRIMARY KEY,
    name              TEXT    NOT NULL,
    symbol            TEXT,
    rank              INTEGER,
    age               INTEGER,
    color             TEXT,
    png32             TEXT,
    all_time_high_usd REAL,
    max_supply        REAL,
    updated_at        INTEGER NOT NULL
  ) WITHOUT ROWID;

  CREATE TABLE IF NOT EXISTS snapshots (
    coin_code      TEXT    NOT NULL REFERENCES coins(code),
    ts             INTEGER NOT NULL,
    rate           REAL    NOT NULL,
    volume         REAL,
    cap            REAL,
    delta_hour     REAL,
    delta_day      REAL,
    delta_week     REAL,
    delta_month    REAL,
    delta_quarter  REAL,
    delta_year     REAL,
    PRIMARY KEY (coin_code, ts)
  ) WITHOUT ROWID;

  CREATE TABLE IF NOT EXISTS supply_snapshots (
    coin_code          TEXT    NOT NULL REFERENCES coins(code),
    ts                 INTEGER NOT NULL,
    circulating_supply REAL,
    total_supply       REAL,
    PRIMARY KEY (coin_code, ts)
  ) WITHOUT ROWID;

  CREATE INDEX IF NOT EXISTS idx_snapshots_ts ON snapshots(ts);
  CREATE INDEX IF NOT EXISTS idx_supply_ts ON supply_snapshots(ts);
`);

db.close();

process.stdout.write(`Database initialized at ${dbPath}\n`);
