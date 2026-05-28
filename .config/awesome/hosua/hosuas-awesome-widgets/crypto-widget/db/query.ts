import "./env-loader";
import { openReadonly } from "./queries/connection";
import { listCoins } from "./queries/coins";
import {
  getRateHistory,
  compareCoins,
  getTopMovers,
  getSupplyHistory,
} from "./queries/snapshots";
import {
  parseTimeArg,
  fmtDate,
  fmtNum,
  fmtDelta,
  formatTable,
} from "./queries/format";
import type { DeltaPeriod } from "./queries/types";

const DELTA_PERIODS: DeltaPeriod[] = [
  "hour",
  "day",
  "week",
  "month",
  "quarter",
  "year",
];

function parseArgs(args: string[]): Record<string, string> {
  const result: Record<string, string> = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith("--")) {
      const key = args[i].slice(2);
      const next = args[i + 1];
      result[key] = next && !next.startsWith("--") ? args[++i] : "true";
    }
  }
  return result;
}

function buildRange(opts: Record<string, string>) {
  const range: { from?: number; to?: number } = {};
  if (opts.from) range.from = parseTimeArg(opts.from);
  if (opts.to) range.to = parseTimeArg(opts.to);
  return range;
}

function printHelp() {
  process.stdout.write(`Usage: pnpm db:query <command> [options]

Commands:
  list      [--limit N] [--sort rank|rate|volume|cap]
  history   --coin CODE [--from 24h|7d|DATE] [--to DATE]
  compare   --coins CODE,CODE[,...] [--from 24h] [--to DATE]
  gainers   [--period hour|day|week|month|quarter|year] [--limit N]
  losers    [--period hour|day|week|month|quarter|year] [--limit N]
  supply    --coin CODE [--from 7d] [--to DATE]
  sql       --query "SELECT ..."

Time arguments accept: relative (24h, 7d, 2w, 1m), ISO date (2025-05-14), or unix seconds.
`);
}

function cmdList(opts: Record<string, string>) {
  const db = openReadonly();
  const limit = opts.limit ? Math.min(Number(opts.limit), 1000) : 50;
  const sortBy = (opts.sort ?? "rank") as "rank" | "rate" | "volume" | "cap";
  const coins = listCoins(db, { limit, sortBy });
  db.close();

  const rows = coins.map((c) => [
    String(c.rank ?? "—"),
    c.code,
    c.name.slice(0, 24),
    fmtNum(c.rate, 4),
    fmtNum(c.volume),
    fmtNum(c.cap),
    fmtDelta(c.delta_day),
    c.ts ? fmtDate(c.ts) : "—",
  ]);
  process.stdout.write(
    formatTable(
      [
        "Rank",
        "Code",
        "Name",
        "Rate (USD)",
        "Volume",
        "Cap",
        "Δ Day",
        "Last Update",
      ],
      rows,
    ) + "\n",
  );
}

function cmdHistory(opts: Record<string, string>) {
  if (!opts.coin) throw new Error("--coin CODE is required");
  const db = openReadonly();
  const rows = getRateHistory(db, opts.coin.toUpperCase(), buildRange(opts));
  db.close();

  if (rows.length === 0) {
    process.stdout.write(`No history found for ${opts.coin}\n`);
    return;
  }
  const tableRows = rows.map((r) => [
    fmtDate(r.ts),
    fmtNum(r.rate, 4),
    fmtNum(r.volume),
    fmtNum(r.cap),
    fmtDelta(r.delta_hour),
    fmtDelta(r.delta_day),
  ]);
  process.stdout.write(
    formatTable(
      ["Timestamp", "Rate (USD)", "Volume", "Cap", "Δ 1h", "Δ 1d"],
      tableRows,
    ) + "\n",
  );
}

function cmdCompare(opts: Record<string, string>) {
  if (!opts.coins) throw new Error("--coins CODE,CODE is required");
  const codes = opts.coins.split(",").map((c) => c.trim().toUpperCase());
  const db = openReadonly();
  const points = compareCoins(db, codes, buildRange(opts));
  db.close();

  if (points.length === 0) {
    process.stdout.write(`No data found for coins: ${codes.join(", ")}\n`);
    return;
  }
  const headers = ["Time", ...codes];
  const tableRows = points.map((p) => [
    fmtDate(p.bucket),
    ...codes.map((code) =>
      p[code] != null ? fmtNum(p[code] as number, 4) : "—",
    ),
  ]);
  process.stdout.write(formatTable(headers, tableRows) + "\n");
}

function cmdMovers(
  opts: Record<string, string>,
  direction: "gainers" | "losers",
) {
  const period = (opts.period ?? "day") as DeltaPeriod;
  if (!DELTA_PERIODS.includes(period)) {
    throw new Error(`--period must be one of: ${DELTA_PERIODS.join(", ")}`);
  }
  const limit = opts.limit ? Number(opts.limit) : 10;
  const db = openReadonly();
  const movers = getTopMovers(db, { period, direction, limit });
  db.close();

  if (movers.length === 0) {
    process.stdout.write(`No data available for period "${period}"\n`);
    return;
  }
  const rows = movers.map((m) => [
    String(m.rank ?? "—"),
    m.code,
    m.name.slice(0, 24),
    fmtNum(m.rate, 4),
    fmtDelta(m.delta),
  ]);
  process.stdout.write(
    formatTable(["Rank", "Code", "Name", "Rate (USD)", `Δ ${period}`], rows) +
      "\n",
  );
}

function cmdSupply(opts: Record<string, string>) {
  if (!opts.coin) throw new Error("--coin CODE is required");
  const db = openReadonly();
  const rows = getSupplyHistory(db, opts.coin.toUpperCase(), buildRange(opts));
  db.close();

  if (rows.length === 0) {
    process.stdout.write(`No supply history found for ${opts.coin}\n`);
    return;
  }
  const tableRows = rows.map((r) => [
    fmtDate(r.ts),
    fmtNum(r.circulating_supply),
    fmtNum(r.total_supply),
  ]);
  process.stdout.write(
    formatTable(
      ["Timestamp", "Circulating Supply", "Total Supply"],
      tableRows,
    ) + "\n",
  );
}

function cmdSql(opts: Record<string, string>) {
  if (!opts.query) throw new Error('--query "SELECT ..." is required');
  const q = opts.query.trim();
  if (!q.toUpperCase().startsWith("SELECT")) {
    throw new Error("Only SELECT queries are allowed");
  }
  const db = openReadonly();
  try {
    const rows = db.prepare(q).all() as Record<string, unknown>[];
    if (rows.length === 0) {
      process.stdout.write("(no rows)\n");
      return;
    }
    const headers = Object.keys(rows[0]);
    const tableRows = rows.map((r) =>
      headers.map((h) => String(r[h] ?? "NULL")),
    );
    process.stdout.write(formatTable(headers, tableRows) + "\n");
    process.stdout.write(`\n(${rows.length} rows)\n`);
  } finally {
    db.close();
  }
}

function main() {
  // Strip pnpm's `--` separator if present as first arg
  const rawArgs = process.argv
    .slice(2)
    .filter((a, i) => !(a === "--" && i === 0));
  const [command, ...rest] = rawArgs;
  const opts = parseArgs(rest);

  try {
    switch (command) {
      case "list":
        return cmdList(opts);
      case "history":
        return cmdHistory(opts);
      case "compare":
        return cmdCompare(opts);
      case "gainers":
        return cmdMovers(opts, "gainers");
      case "losers":
        return cmdMovers(opts, "losers");
      case "supply":
        return cmdSupply(opts);
      case "sql":
        return cmdSql(opts);
      default:
        printHelp();
        if (command) process.stderr.write(`Unknown command: ${command}\n`);
        process.exit(command ? 1 : 0);
    }
  } catch (err) {
    process.stderr.write(`Error: ${(err as Error).message}\n`);
    process.exit(1);
  }
}

main();
