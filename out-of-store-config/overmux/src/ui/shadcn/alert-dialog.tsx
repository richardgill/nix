import * as AlertDialogPrimitive from "@radix-ui/react-alert-dialog";
import { forwardRef } from "react";
import type { ComponentProps, HTMLAttributes } from "react";

import { cn } from "./utils";

export const AlertDialog = AlertDialogPrimitive.Root;
export const AlertDialogAction = AlertDialogPrimitive.Action;
export const AlertDialogCancel = AlertDialogPrimitive.Cancel;

export const AlertDialogContent = forwardRef<
  HTMLDivElement,
  ComponentProps<typeof AlertDialogPrimitive.Content>
>(({ className, ...props }, ref) => (
  <AlertDialogPrimitive.Portal>
    <AlertDialogPrimitive.Overlay className="fixed inset-0 z-[1100] bg-black/70" />
    <AlertDialogPrimitive.Content
      className={cn(
        "fixed top-1/2 left-1/2 z-[1101] w-[calc(100%-2rem)] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded border bg-background p-4 shadow-xl",
        className,
      )}
      ref={ref}
      {...props}
    />
  </AlertDialogPrimitive.Portal>
));

AlertDialogContent.displayName = "AlertDialogContent";

export const AlertDialogHeader = ({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("grid gap-2", className)} {...props} />
);

export const AlertDialogFooter = ({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) => (
  <div
    className={cn("mt-4 flex justify-end gap-2", className)}
    {...props}
  />
);

export const AlertDialogTitle = forwardRef<
  HTMLHeadingElement,
  ComponentProps<typeof AlertDialogPrimitive.Title>
>(({ className, ...props }, ref) => (
  <AlertDialogPrimitive.Title
    className={cn("font-semibold", className)}
    ref={ref}
    {...props}
  />
));

AlertDialogTitle.displayName = "AlertDialogTitle";

export const AlertDialogDescription = forwardRef<
  HTMLParagraphElement,
  ComponentProps<typeof AlertDialogPrimitive.Description>
>(({ className, ...props }, ref) => (
  <AlertDialogPrimitive.Description
    className={cn("break-all text-sm text-foreground/70", className)}
    ref={ref}
    {...props}
  />
));

AlertDialogDescription.displayName = "AlertDialogDescription";
