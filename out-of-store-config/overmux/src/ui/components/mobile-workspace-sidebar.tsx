// Mobile-only workspace navigation keeps terminal controls out of the drawer.
// The Sheet primitive provides modal dismissal and focus management.
// Session order is supplied by tmux state and deliberately left unchanged.
import { Bell, RefreshCw, Settings, SquareTerminal, X } from "lucide-react";
import { useEffect, useRef } from "react";
import type { RefObject } from "react";

import { DialogTitle } from "../shadcn/dialog";
import { Sheet, SheetContent } from "../shadcn/sheet";
import { cn } from "../shadcn/utils";

type MobileWorkspaceSidebarProps = {
  onNotifications: () => void;
  onResetFontSize: () => void;
  openerRef: RefObject<HTMLButtonElement | null>;
  onOpenChange: (open: boolean) => void;
  onSelectSession: (sessionId: string) => void;
  onSettings: () => void;
  open: boolean;
  selectedSessionId: string | null;
  sessions: readonly { id: string; name: string }[];
};

export const MobileWorkspaceSidebar = ({
  onNotifications,
  onResetFontSize = () => null,
  openerRef,
  onOpenChange,
  onSelectSession,
  onSettings,
  open,
  selectedSessionId,
  sessions,
}: MobileWorkspaceSidebarProps) => {
  const restoreFocus = useRef(true);

  useEffect(() => {
    const media = window.matchMedia("(min-width: 768px)");
    const closeOnDesktop = () => {
      if (!media.matches || !open) return;
      restoreFocus.current = false;
      onOpenChange(false);
    };
    closeOnDesktop();
    media.addEventListener("change", closeOnDesktop);
    return () => media.removeEventListener("change", closeOnDesktop);
  }, [onOpenChange, open]);

  const closeForAction = () => {
    restoreFocus.current = false;
    onOpenChange(false);
  };

  return (
    <Sheet onOpenChange={onOpenChange} open={open}>
      <SheetContent
        aria-describedby={undefined}
        aria-label="Workspace"
        className="gap-0 p-0 md:hidden"
        onCloseAutoFocus={(event) => {
          event.preventDefault();
          if (restoreFocus.current) openerRef.current?.focus();
          restoreFocus.current = true;
        }}
        side="right"
      >
        <DialogTitle className="sr-only">Workspace</DialogTitle>
        <header className="flex shrink-0 items-center justify-end gap-1 border-b p-1">
          <button
            aria-label="Refresh app"
            className="flex size-10 items-center justify-center rounded hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
            onClick={() => window.location.assign("/")}
            title="Refresh app"
            type="button"
          >
            <RefreshCw aria-hidden="true" className="size-5" />
          </button>
          <button
            aria-label="Open settings"
            className="flex size-10 items-center justify-center rounded hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
            onClick={() => {
              closeForAction();
              onSettings();
            }}
            type="button"
          >
            <Settings aria-hidden="true" className="size-5" />
          </button>
          <button
            aria-label="Close workspace menu"
            className="flex size-10 items-center justify-center rounded hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
            onClick={() => onOpenChange(false)}
            type="button"
          >
            <X aria-hidden="true" className="size-5" />
          </button>
        </header>
        <nav className="shrink-0 p-2" aria-label="Workspace actions">
          <button
            className="flex min-h-[2.375rem] w-full items-center gap-1 border-l-4 border-transparent px-2 py-2 text-left text-sm leading-5 hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
            onClick={() => {
              closeForAction();
              onNotifications();
            }}
            type="button"
          >
            <Bell aria-hidden="true" className="size-5 shrink-0" />
            <span className="truncate">Notifications</span>
          </button>
          <button
            className="flex min-h-[2.375rem] w-full items-center gap-1 border-l-4 border-transparent px-2 py-2 text-left text-sm leading-5 hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
            onClick={() => {
              closeForAction();
              onResetFontSize();
            }}
            type="button"
          >
            Reset terminal font size
          </button>
        </nav>
        <div className="min-h-0 flex-1 overflow-y-auto border-t p-2" aria-label="Tmux sessions">
          <div className="flex flex-col gap-1">
            {sessions.map((session) => {
              const selected = session.id === selectedSessionId;
              return (
                <button
                  aria-current={selected ? "page" : undefined}
                  className={cn(
                    "flex min-h-[2.375rem] min-w-0 items-center gap-1 border-l-4 border-transparent px-2 py-2 text-left text-sm leading-5 hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent",
                    selected && "border-accent bg-accent/15 font-bold text-accent",
                  )}
                  key={session.id}
                  onClick={() => {
                    closeForAction();
                    onSelectSession(session.id);
                  }}
                  type="button"
                >
                  <SquareTerminal
                    aria-hidden="true"
                    className="size-5 shrink-0"
                  />
                  <span className="min-w-0 flex-1 truncate">{session.name}</span>
                </button>
              );
            })}
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
};
