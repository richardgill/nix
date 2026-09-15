import type { KeyboardEventHandler, ReactNode } from "react";

import { Dialog, DialogContent } from "../shadcn/dialog";
import { Kbd } from "../shadcn/kbd";

type FullscreenDialogProps = {
  children: ReactNode;
  onClose: () => void;
  // Restores focus after the dialog closes.
  onCloseAutoFocus?: () => void;
  onKeyDown?: KeyboardEventHandler<HTMLDivElement>;
  open: boolean;
};

export const FullscreenDialog = ({
  children,
  onClose,
  onCloseAutoFocus,
  onKeyDown,
  open,
}: FullscreenDialogProps) => (
  <Dialog onOpenChange={(nextOpen) => !nextOpen && onClose()} open={open}>
    <DialogContent
      aria-describedby={undefined}
      aria-modal="true"
      className="flex h-dvh w-full! max-w-none! flex-col overflow-hidden rounded-none! border-0! p-0! md:h-[calc(100dvh-2rem)] md:w-[calc(100%-2rem)]! md:rounded! md:border!"
      closeHint={
        <span aria-hidden="true" className="hidden items-center gap-1 md:inline-flex">
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
        const quit = event.key === "q" && !event.ctrlKey && !event.metaKey && !event.altKey;
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
