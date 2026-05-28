import { useState, useCallback, useMemo } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Header } from "@/components/header";
import { CoinGrid } from "@/components/coin-grid";
import { CoinSelector } from "@/components/coin-selector";
import { useCoins } from "@/hooks/use-coins";
import { useTheme, ThemeContext } from "@/hooks/use-theme";

const STORAGE_KEY = "crypto-selected-coins";

function loadSelection(): Set<string> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? new Set(JSON.parse(raw) as string[]) : new Set();
  } catch {
    return new Set();
  }
}

function saveSelection(s: Set<string>) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify([...s]));
}

const queryClient = new QueryClient();

function Dashboard() {
  const { data: coins = [], isLoading, error } = useCoins();
  const [selected, setSelected] = useState<Set<string>>(loadSelection);

  const handleSelectionChange = useCallback((next: Set<string>) => {
    setSelected(next);
    saveSelection(next);
  }, []);

  const visibleCoins = useMemo(
    () => (selected.size === 0 ? coins : coins.filter((c) => selected.has(c.code))),
    [coins, selected]
  );

  const lastUpdated = useMemo(
    () => (coins.length > 0 ? Math.max(...coins.map((c) => c.ts ?? 0)) : null),
    [coins]
  );

  return (
    <div className="min-h-screen bg-background">
      <Header coinCount={visibleCoins.length} lastUpdated={lastUpdated} />
      <main className="max-w-screen-2xl mx-auto px-6 py-5">
        {error ? (
          <div className="text-center py-20">
            <p className="text-destructive text-sm">
              Failed to load coins. Is the API server running?
            </p>
            <p className="text-muted-foreground text-xs mt-1">
              Run:{" "}
              <code className="bg-secondary px-1.5 py-0.5 rounded text-foreground">
                npm run dev:server
              </code>
            </p>
          </div>
        ) : (
          <>
            <div className="mb-4">
              <CoinSelector
                coins={coins}
                selected={selected}
                onChange={handleSelectionChange}
              />
            </div>
            <CoinGrid coins={visibleCoins} isLoading={isLoading} />
          </>
        )}
      </main>
    </div>
  );
}

function ThemeProvider({ children }: { children: React.ReactNode }) {
  const theme = useTheme();
  return <ThemeContext.Provider value={theme}>{children}</ThemeContext.Provider>;
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <Dashboard />
      </ThemeProvider>
    </QueryClientProvider>
  );
}
