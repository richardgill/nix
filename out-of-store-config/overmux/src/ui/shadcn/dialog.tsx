import * as DialogPrimitive from "@radix-ui/react-dialog";
import { X } from "lucide-react";
import { OvermuxPortal } from "overmux/client";
import { forwardRef } from "react";
import type { ComponentProps, HTMLAttributes, ReactNode } from "react";

import { cn } from "./utils";

export const Dialog = DialogPrimitive.Root;
export const DialogClose = DialogPrimitive.Close;

export const DialogContent = forwardRef<
  HTMLDivElement,
  ComponentProps<typeof DialogPrimitive.Content> & { closeHint?: ReactNode }
>(({ children, className, closeHint, ...props }, ref) => (
  <OvermuxPortal>
    <DialogPrimitive.Overlay className="fixed inset-0 z-[1100] bg-black/70" />
    <DialogPrimitive.Content
      className={cn(
        "fixed top-1/2 left-1/2 z-[1101] w-[calc(100%-2rem)] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded border bg-background p-4 shadow-xl",
        className,
      )}
      ref={ref}
      {...props}
    >
      {children}
      <DialogPrimitive.Close className="absolute top-3 right-3 inline-flex items-center gap-2 rounded p-1 text-foreground/60 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent">
        {closeHint}
        <X className="size-4" />
        <span className="sr-only">Close</span>
      </DialogPrimitive.Close>
    </DialogPrimitive.Content>
  </OvermuxPortal>
));

DialogContent.displayName = "DialogContent";

export const DialogHeader = ({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("grid gap-2 pr-6", className)} {...props} />
);

export const DialogFooter = ({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("mt-4 flex justify-end gap-2", className)} {...props} />
);

export const DialogTitle = forwardRef<
  HTMLHeadingElement,
  ComponentProps<typeof DialogPrimitive.Title>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Title
    className={cn("font-semibold", className)}
    ref={ref}
    {...props}
  />
));

DialogTitle.displayName = "DialogTitle";

export const DialogDescription = forwardRef<
  HTMLParagraphElement,
  ComponentProps<typeof DialogPrimitive.Description>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Description
    className={cn("break-all text-sm text-foreground/70", className)}
    ref={ref}
    {...props}
  />
));

DialogDescription.displayName = "DialogDescription";
