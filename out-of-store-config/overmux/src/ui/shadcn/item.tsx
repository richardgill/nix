import { forwardRef } from "react";
import type { HTMLAttributes } from "react";

import { cn } from "./utils";

export const Item = forwardRef<HTMLDivElement, HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div
      className={cn(
        "flex min-w-0 items-stretch gap-2 rounded-lg border bg-background",
        className,
      )}
      ref={ref}
      {...props}
    />
  ),
);

Item.displayName = "Item";

export const ItemContent = forwardRef<
  HTMLDivElement,
  HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    className={cn("flex min-w-0 flex-1 flex-col gap-1", className)}
    ref={ref}
    {...props}
  />
));

ItemContent.displayName = "ItemContent";

export const ItemTitle = forwardRef<
  HTMLDivElement,
  HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    className={cn("min-w-0 text-sm font-medium", className)}
    ref={ref}
    {...props}
  />
));

ItemTitle.displayName = "ItemTitle";

export const ItemDescription = forwardRef<
  HTMLDivElement,
  HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    className={cn("text-sm text-foreground/60", className)}
    ref={ref}
    {...props}
  />
));

ItemDescription.displayName = "ItemDescription";

export const ItemActions = forwardRef<
  HTMLDivElement,
  HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    className={cn("flex shrink-0 items-center gap-1", className)}
    ref={ref}
    {...props}
  />
));

ItemActions.displayName = "ItemActions";
