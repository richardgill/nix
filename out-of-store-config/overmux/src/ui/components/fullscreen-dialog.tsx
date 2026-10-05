import type { KeyboardEventHandler, ReactNode } from "react";

import { Dialog, DialogContent } from "../shadcn/dialog";
import { Kbd } from "../shadcn/kbd";
import { cn } from "../shadcn/utils";

type FullscreenDialogProps = {
  children: ReactNode;
  edgeToEdge?: boolean;
  onClose: () => void;
  // Restores focus after the dialog closes.
  onCloseAutoFocus?: () => void;
  onKeyDown?: KeyboardEventHandler<HTMLDivElement>;
  open: boolean;
  hideCloseButton?: boolean;
};

export const FullscreenDialog = ({
  children,
  edgeToEdge = false,
  onClose,
  onCloseAutoFocus,
  onKeyDown,
  open,
  hideCloseButton,
}: FullscreenDialogProps) => (
  <Dialog onOpenChange={(nextOpen) => !nextOpen && onClose()} open={open}>
    <DialogContent
      aria-describedby={undefined}
      aria-modal="true"
      className={cn(
        "flex h-dvh w-full! max-w-none! flex-col overflow-hidden rounded-none! border-0! p-0!",
        !edgeToEdge &&
          "[@media(min-width:768px)_and_(pointer:fine)]:h-[calc(100dvh-2rem)] [@media(min-width:768px)_and_(pointer:fine)]:w-[calc(100%-2rem)]! [@media(min-width:768px)_and_(pointer:fine)]:rounded! [@media(min-width:768px)_and_(pointer:fine)]:border!",
      )}
      hideCloseButton={hideCloseButton}
      closeHint={
        <span
          aria-hidden="true"
          className="hidden items-center gap-1 [@media(min-width:768px)_and_(pointer:fine)]:inline-flex"
        >
          <Kbd>q</Kbd>
          <Kbd>Esc</Kbd>
        </span>
      }
      onCloseAutoFocus={(event) => {
        if (!onCloseAutoFocus) return;
        event.preventDefault();
        onCloseAutoFocus();
      }}
      onOpenAutoFocus={(event) => {
        event.preventDefault();
        (event.target as HTMLElement).focus();
      }}
      onKeyDownCapture={(event) => {
        const quit =
          event.key === "q" &&
          !event.ctrlKey &&
          !event.metaKey &&
          !event.altKey;
        if (event.key === "Escape" || quit) {
          event.preventDefault();
          event.stopPropagation();
          onClose();
          return;
        }
        onKeyDown?.(event);
      }}
    >
      {children}
    </DialogContent>
  </Dialog>
);
