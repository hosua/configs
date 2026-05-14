import { useQuery } from "@tanstack/react-query";
import type { CoinData } from "@/types/coin";

async function fetchCoins(): Promise<CoinData[]> {
  const res = await fetch("/api/coins?limit=100");
  if (!res.ok) throw new Error(`Failed to fetch coins: ${res.status}`);
  return res.json() as Promise<CoinData[]>;
}

export function useCoins() {
  return useQuery({
    queryKey: ["coins"],
    queryFn: fetchCoins,
    refetchInterval: 30_000,
    staleTime: 20_000,
  });
}
