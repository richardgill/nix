import * as Dialog from "@radix-ui/react-dialog";
import { forwardRef } from "react";
import type { ComponentProps } from "react";

import { cn } from "./utils";

export const Sheet = Dialog.Root;

export const SheetContent = forwardRef<
  HTMLDivElement,
  ComponentProps<typeof Dialog.Content> & { side?: "left" | "right" }
>(({ className, side = "right", ...props }, ref) => (
  <Dialog.Portal>
    <Dialog.Overlay className="fixed inset-0 z-40 bg-black/50" />
    <Dialog.Content
      className={cn(
        "fixed inset-y-0 z-50 flex w-72 flex-col bg-background shadow-xl",
        side === "left" ? "left-0 border-r" : "right-0 border-l",
        className,
      )}
      ref={ref}
      {...props}
    />
  </Dialog.Portal>
));

SheetContent.displayName = "SheetContent";
