import { useState } from "react";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Button } from "@/components/ui/button";
import { CoinIcon } from "@/components/coin-icon";
import { stripUnderscores } from "@/lib/format";
import { Check, ChevronDown, X } from "lucide-react";
import { cn } from "@/lib/utils";
import type { CoinData } from "@/types/coin";

interface Props {
  coins: CoinData[];
  selected: Set<string>;
  onChange: (next: Set<string>) => void;
}

export function CoinSelector({ coins, selected, onChange }: Props) {
  const [open, setOpen] = useState(false);

  const allSelected = selected.size === 0;
  const label = allSelected
    ? "All coins"
    : selected.size === 1
      ? stripUnderscores([...selected][0])
      : `${selected.size} coins`;

  function toggle(code: string) {
    const next = new Set(selected);
    if (next.has(code)) {
      next.delete(code);
    } else {
      next.add(code);
    }
    onChange(next);
  }

  function selectAll() {
    onChange(new Set());
    setOpen(false);
  }

  return (
    <div className="flex items-center gap-2">
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button
            variant="outline"
            size="sm"
            className="h-8 gap-1.5 border-border bg-secondary/50 text-foreground hover:bg-secondary text-xs font-normal min-w-[110px] justify-between"
          >
            <span>{label}</span>
            <ChevronDown className="w-3 h-3 text-muted-foreground" />
          </Button>
        </PopoverTrigger>
        <PopoverContent
          className="w-64 p-0 bg-popover border-border"
          align="start"
        >
          <Command className="bg-transparent">
            <CommandInput
              placeholder="Search coins…"
              className="h-9 text-sm border-b border-border"
            />
            <CommandList className="max-h-64">
              <CommandEmpty className="text-xs text-muted-foreground py-4 text-center">
                No coins found.
              </CommandEmpty>
              <CommandGroup>
                {/* Show all option */}
                <CommandItem
                  onSelect={selectAll}
                  className="flex items-center gap-2 text-xs cursor-pointer"
                >
                  <div
                    className={cn(
                      "w-3.5 h-3.5 rounded border border-border flex items-center justify-center shrink-0",
                      allSelected && "bg-primary border-primary"
                    )}
                  >
                    {allSelected && <Check className="w-2.5 h-2.5 text-primary-foreground" />}
                  </div>
                  <span className="font-medium">All coins</span>
                </CommandItem>

                {coins.map((coin) => {
                  const code = coin.code;
                  const display = stripUnderscores(code);
                  const checked = selected.has(code);
                  return (
                    <CommandItem
                      key={code}
                      value={`${display} ${coin.name}`}
                      onSelect={() => toggle(code)}
                      className="flex items-center gap-2 text-xs cursor-pointer"
                    >
                      <div
                        className={cn(
                          "w-3.5 h-3.5 rounded border border-border flex items-center justify-center shrink-0",
                          checked && "bg-primary border-primary"
                        )}
                      >
                        {checked && <Check className="w-2.5 h-2.5 text-primary-foreground" />}
                      </div>
                      <CoinIcon
                        src={coin.png32}
                        code={display}
                        color={coin.color}
                        size={16}
                        className="shrink-0"
                      />
                      <span className="font-medium">{display}</span>
                      <span className="text-muted-foreground truncate">{coin.name}</span>
                    </CommandItem>
                  );
                })}
              </CommandGroup>
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>

      {/* Clear selection badge */}
      {!allSelected && (
        <button
          onClick={() => onChange(new Set())}
          className="flex items-center gap-1 text-[11px] text-muted-foreground hover:text-foreground transition-colors"
        >
          <X className="w-3 h-3" />
          Clear
        </button>
      )}
    </div>
  );
}
