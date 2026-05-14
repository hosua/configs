import { Skeleton } from "@/components/ui/skeleton";
import { CoinCard } from "@/components/coin-card";
import type { CoinData } from "@/types/coin";

interface Props {
  coins: CoinData[];
  isLoading: boolean;
}

function LoadingSkeleton() {
  return (
    <>
      {Array.from({ length: 12 }).map((_, i) => (
        <div key={i} className="rounded-lg border border-border bg-card p-4 flex flex-col gap-3">
          <div className="flex items-center gap-2.5">
            <Skeleton className="w-7 h-7 rounded-full" />
            <div className="flex flex-col gap-1">
              <Skeleton className="w-12 h-3" />
              <Skeleton className="w-20 h-2.5" />
            </div>
          </div>
          <Skeleton className="w-28 h-5" />
          <div className="flex justify-between pt-2 border-t border-border">
            {Array.from({ length: 4 }).map((_, j) => (
              <Skeleton key={j} className="w-10 h-6" />
            ))}
          </div>
        </div>
      ))}
    </>
  );
}

export function CoinGrid({ coins, isLoading }: Props) {
  return (
    <div
      className="grid gap-3"
      style={{ gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))" }}
    >
      {isLoading ? (
        <LoadingSkeleton />
      ) : (
        coins.map((coin) => <CoinCard key={coin.code} coin={coin} />)
      )}
    </div>
  );
}
