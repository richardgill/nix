import { forwardRef } from "react";
import type { ButtonHTMLAttributes } from "react";

import { cn } from "./utils";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  size?: "default" | "icon" | "sm";
  variant?: "default" | "destructive" | "ghost" | "outline";
};

const variants = {
  default: "border-transparent bg-accent text-background hover:opacity-90",
  destructive:
    "border-red-500 bg-red-950 text-red-100 hover:bg-red-900 disabled:opacity-50",
  ghost: "border-transparent bg-transparent hover:bg-panel-muted",
  outline: "border-border bg-background hover:bg-panel-muted",
} as const;

const sizes = {
  default: "min-h-10 px-4 py-2",
  icon: "size-9 p-0",
  sm: "min-h-9 px-3 py-1.5 text-sm",
} as const;

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    { className, size = "default", type = "button", variant = "default", ...props },
    ref,
  ) => (
    <button
      className={cn(
        "inline-flex items-center justify-center rounded border font-medium transition-colors focus-visible:border-accent focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50",
        variants[variant],
        sizes[size],
        className,
      )}
      ref={ref}
      type={type}
      {...props}
    />
  ),
);

Button.displayName = "Button";
