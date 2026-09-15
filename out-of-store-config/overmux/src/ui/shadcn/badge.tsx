import type { HTMLAttributes } from "react";

import { cn } from "./utils";

export const Badge = ({
  className,
  ...props
}: HTMLAttributes<HTMLSpanElement>) => (
  <span
    className={cn(
      "inline-flex items-center rounded-md border border-border bg-panel-muted px-2 py-0.5 text-xs font-medium text-foreground",
      className,
    )}
    {...props}
  />
);
