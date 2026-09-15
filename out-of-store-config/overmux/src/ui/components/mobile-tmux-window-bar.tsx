// Renders the mobile-only, route-controlled tmux window tabs.
// Keeps the confirmed active tab within this bar's horizontal viewport.
// Labels zsh windows from their active pane directory when available.
import { Plus, X } from "lucide-react";
import { type PointerEvent, useEffect, useRef } from "react";

import { cn } from "../shadcn/utils";

export type WindowTab = Readonly<{ id: string; label: string }>;

export type MobileTmuxWindowBarProps = {
  activeWindowId: string | null;
  actionsDisabled: boolean;
  onCreatePiWindow: () => void;
  onKillActivePane: () => void;
  onSelectWindow: (windowId: string) => void;
  tabs: readonly WindowTab[];
};

export const tmuxWindowLabel = ({
  activePaneDirectory,
  windowName,
}: {
  activePaneDirectory: string | null;
  windowName: string;
}) => {
  if (windowName !== "zsh" || !activePaneDirectory) {
    return windowName;
  }
  const directory = activePaneDirectory.replace(/\/+$/, "");
  return directory.split("/").pop() || "zsh";
};

const preserveTerminalFocus = (event: PointerEvent<HTMLButtonElement>) => {
  const focusedElement = event.currentTarget.ownerDocument.activeElement;
  if (
    event.button === 0 &&
    focusedElement?.matches(".xterm .xterm-helper-textarea")
  ) {
    // Keep the mobile keyboard open without cancelling tab clicks or scrolling.
    event.preventDefault();
  }
};

export const MobileTmuxWindowBar = ({
  activeWindowId,
  actionsDisabled,
  onCreatePiWindow,
  onKillActivePane,
  onSelectWindow,
  tabs,
}: MobileTmuxWindowBarProps) => {
  const barRef = useRef<HTMLDivElement>(null);
  const activeTabRef = useRef<HTMLButtonElement>(null);
  const tabsKey = tabs.map(({ id, label }) => `${id}\u0000${label}`).join("\u0001");

  useEffect(() => {
    const bar = barRef.current;
    const tab = activeTabRef.current;
    if (!bar || !tab) return;
    const keepActiveTabVisible = () => {
      const left = tab.offsetLeft;
      const right = left + tab.offsetWidth;
      const visibleRight = bar.scrollLeft + bar.clientWidth;
      if (left < bar.scrollLeft) bar.scrollLeft = left;
      if (right > visibleRight) bar.scrollLeft = right - bar.clientWidth;
    };
    keepActiveTabVisible();
    if (typeof ResizeObserver === "undefined") return;
    const observer = new ResizeObserver(keepActiveTabVisible);
    observer.observe(bar);
    return () => observer.disconnect();
  }, [activeWindowId, tabsKey]);

  return (
    <nav
      aria-label="Tmux windows"
      className="flex shrink-0 border-b bg-background md:hidden"
    >
      <div className="relative flex min-w-0 flex-1 overflow-x-auto" ref={barRef}>
        {tabs.map((tab) => {
          const active = tab.id === activeWindowId;
          return (
            <button
              aria-current={active ? "page" : undefined}
              className={cn(
                "min-h-10 shrink-0 border-b-2 border-transparent px-3 text-sm hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent",
                active && "border-accent bg-accent/15 font-bold text-accent",
              )}
              key={tab.id}
              onClick={() => onSelectWindow(tab.id)}
              onPointerDown={preserveTerminalFocus}
              ref={active ? activeTabRef : undefined}
              type="button"
            >
              {tab.label}
            </button>
          );
        })}
      </div>
      <div className="flex shrink-0 border-l">
        <button
          aria-label="Create Pi window"
          className="flex size-10 items-center justify-center hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
          disabled={actionsDisabled}
          onClick={onCreatePiWindow}
          type="button"
        >
          <Plus aria-hidden="true" className="size-5" />
        </button>
        <button
          aria-label="Kill active tmux pane"
          className="flex size-10 items-center justify-center hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
          disabled={actionsDisabled}
          onClick={onKillActivePane}
          type="button"
        >
          <X aria-hidden="true" className="size-5" />
        </button>
      </div>
    </nav>
  );
};
