import { useQuery } from "@tanstack/react-query";

export interface HistoryPoint {
  ts: number;
  rate: number;
}

export function useCoinHistory(code: string) {
  return useQuery({
    queryKey: ["coin-history", code],
    queryFn: async () => {
      const res = await fetch(`/api/coins/${encodeURIComponent(code)}/history?days=3`);
      if (!res.ok) throw new Error(`Failed: ${res.status}`);
      return res.json() as Promise<HistoryPoint[]>;
    },
    staleTime: 60_000,
    refetchInterval: 60_000,
  });
}
