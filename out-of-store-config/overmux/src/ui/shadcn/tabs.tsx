import * as TabsPrimitive from "@radix-ui/react-tabs";
import { forwardRef } from "react";
import type { ComponentProps } from "react";

import { cn } from "./utils";

export const Tabs = TabsPrimitive.Root;

export const TabsList = forwardRef<
  HTMLDivElement,
  ComponentProps<typeof TabsPrimitive.List>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.List
    className={cn("flex min-w-max items-end", className)}
    ref={ref}
    {...props}
  />
));

TabsList.displayName = "TabsList";

export const TabsTrigger = forwardRef<
  HTMLButtonElement,
  ComponentProps<typeof TabsPrimitive.Trigger>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.Trigger
    className={cn(
      "relative inline-flex min-h-8 items-center px-2 text-sm text-foreground/70 hover:text-foreground data-[state=active]:font-bold data-[state=active]:text-accent after:absolute after:right-2 after:bottom-0 after:left-2 after:h-0.5 after:bg-transparent data-[state=active]:after:bg-accent",
      className,
    )}
    ref={ref}
    {...props}
  />
));

TabsTrigger.displayName = "TabsTrigger";
