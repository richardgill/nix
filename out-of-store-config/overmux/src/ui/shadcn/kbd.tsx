import type { ComponentProps } from "react";

import { cn } from "./utils";

// Adapted to Overmux theme tokens from https://github.com/shadcn-ui/ui/blob/main/apps/v4/registry/new-york-v4/ui/kbd.tsx
export const Kbd = ({ className, ...props }: ComponentProps<"kbd">) => (
  <kbd
    data-slot="kbd"
    className={cn(
      "pointer-events-none hidden md:inline-flex h-5 w-fit min-w-5 items-center justify-center gap-1 rounded-sm bg-panel-muted px-1 font-sans text-xs font-medium text-foreground/60 select-none",
      "[&_svg:not([class*='size-'])]:size-3",
      className,
    )}
    {...props}
  />
);

export const KbdGroup = ({ className, ...props }: ComponentProps<"kbd">) => (
  <kbd
    data-slot="kbd-group"
    className={cn("hidden items-center gap-1 md:inline-flex", className)}
    {...props}
  />
);
