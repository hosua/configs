import "./env-loader";
import { writeFileSync } from "fs";
import { getFiats, getCoinList, getCoinMap } from "./liveCoinWatchApi";
import type { CoinSort, Order } from "./types";

function parseArgs(args: string[]): Record<string, string> {
  const result: Record<string, string> = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith("--")) {
      const key = args[i].slice(2);
      const next = args[i + 1];
      const val = next && !next.startsWith("--") ? args[++i] : "true";
      result[key] = val;
    }
  }
  return result;
}

async function main() {
  const [command, ...rest] = process.argv.slice(2);
  const opts = parseArgs(rest);

  switch (command) {
    case "getCoinList": {
      const data = await getCoinList({
        currency: opts.currency,
        sort: opts.sort as CoinSort,
        order: opts.order as Order,
        offset: opts.offset !== undefined ? Number(opts.offset) : undefined,
        limit: opts.limit !== undefined ? Number(opts.limit) : undefined,
      });
      writeFileSync("coin-list.json", JSON.stringify(data, null, 2));
      console.log("Saved to coin-list.json");
      break;
    }

    case "getCoinMap": {
      if (!opts.codes) {
        throw new Error("--codes is required (comma-separated, e.g. BTC,ETH,XMR)");
      }
      const data = await getCoinMap({
        codes: opts.codes.split(","),
        currency: opts.currency,
        sort: opts.sort as CoinSort,
        order: opts.order as Order,
        offset: opts.offset !== undefined ? Number(opts.offset) : undefined,
      });
      writeFileSync("coin-map.json", JSON.stringify(data, null, 2));
      console.log("Saved to coin-map.json");
      break;
    }

    case "getFiats": {
      const data = await getFiats();
      writeFileSync("fiats.json", JSON.stringify(data, null, 2));
      console.log("Saved to fiats.json");
      break;
    }

    default:
      console.error(`Unknown command: ${command ?? "(none)"}`);
      console.error("Usage: npm run <getCoinList|getCoinMap|getFiats> [-- --option value ...]");
      console.error("");
      console.error("  getCoinList  [--currency USD] [--sort rank] [--order ascending] [--offset 0] [--limit 100]");
      console.error("  getCoinMap   --codes BTC,ETH,XMR [--currency USD] [--sort rank] [--order ascending] [--offset 0]");
      console.error("  getFiats");
      process.exit(1);
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
