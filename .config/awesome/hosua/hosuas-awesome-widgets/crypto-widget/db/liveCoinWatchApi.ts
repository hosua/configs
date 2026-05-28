import axios from "axios";

import type { CoinSort, Order } from "./types";

const BASE_URL = "https://api.livecoinwatch.com/";

const API_KEYS = (process.env.LIVECOIN_API_KEYS ?? "")
  .split(",")
  .map((k) => k.trim())
  .filter(Boolean);

if (API_KEYS.length === 0) {
  throw new Error("LIVECOIN_API_KEYS is not set or empty");
}

async function postWithKeyRotation(endpoint: string, body: unknown) {
  let lastError: Error | undefined;
  for (const key of API_KEYS) {
    try {
      const { data } = await axios.post(`${BASE_URL}${endpoint}`, body, {
        headers: { "x-api-key": key },
      });
      return data;
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
    }
  }
  throw lastError ?? new Error("All API keys exhausted");
}

const getFiats = async () => {
  return postWithKeyRotation("fiats/all", null);
};

interface GetCoinListProps {
  currency?: string;
  sort?: CoinSort;
  order?: Order;
  offset?: number;
  limit?: number; // max 100
}

const getCoinList = async ({
  currency = "USD",
  sort = "rank",
  order = "ascending",
  offset = 0,
  limit = 100,
}: GetCoinListProps = {}) => {
  return postWithKeyRotation("coins/list", { currency, sort, order, offset, limit, meta: true });
};

interface GetCoinMapProps {
  codes: string[];
  currency?: string;
  sort?: CoinSort;
  order?: Order;
  offset?: number;
}

const getCoinMap = async ({
  codes,
  currency = "USD",
  sort = "rank",
  order = "ascending",
  offset = 0,
}: GetCoinMapProps) => {
  return postWithKeyRotation("coins/map", { codes, currency, sort, order, offset, meta: true });
};

export { getFiats, getCoinList, getCoinMap };
export default { getFiats, getCoinList, getCoinMap };
