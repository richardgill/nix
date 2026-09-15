import "./css/styles.css";

import {
  orderedChanges,
  registerGitDiffTheme,
  SourceControlView,
  sourceControlCommands,
  type GitDiffOptions,
} from "@overmux/git/react";
import type { GitSourceControl } from "@overmux/git/shared";
import { PiConversation } from "@overmux/pi/react";
import tokyoNight from "@shikijs/themes/tokyo-night";
import { TmuxXterm } from "@overmux/tmux/react";
import { tmuxStateSchema } from "@overmux/tmux/shared";
import type { XtermTerminalHandle } from "@overmux/xterm/react";
import { createSafeWebglAddon } from "@overmux/xterm/webgl";
import {
  ClipboardAddon,
  type IClipboardProvider,
} from "@xterm/addon-clipboard";
import {
  createOvermuxHooks,
  defineCommandRegistry,
  defineOvermuxClient,
  skipToken,
  useCommand,
  useCommands,
} from "overmux/client";
import { Trash2 } from "lucide-react";
import {
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { createPortal } from "react-dom";
import { z } from "zod";

import type {
  StoredNotification,
  TmuxSessionPickerEntry,
} from "../../zod-schemas";
import { MobileWindowSwiper } from "./mobile-window-swiper";
import { TmuxSidebar } from "./tmux-sidebar";
import { Badge } from "../shadcn/badge";
import { Button } from "../shadcn/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "../shadcn/dialog";
import {
  Item,
  ItemActions,
  ItemContent,
  ItemTitle,
} from "../shadcn/item";
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
  useIsMobile,
} from "../shadcn/sidebar";
import { Tabs, TabsList, TabsTrigger } from "../shadcn/tabs";

type ServerConfig = typeof import("../../server").default;
type TmuxState = z.infer<typeof tmuxStateSchema>;
type TmuxSession = TmuxState["hierarchy"]["sessions"][number];
type TmuxWindow = TmuxSession["windows"][number];

type ClipboardHost = {
  clipboard?: { version: 1; writeText: (text: string) => void };
};

const terminalClipboardProvider = {
  readText: () => "",
  writeText: (selection, text) => {
    if (selection !== "c") {
      return;
    }
    const host = (window as Window & { overmuxHost?: ClipboardHost })
      .overmuxHost;
    if (host?.clipboard) {
      host.clipboard.writeText(text);
      return;
    }
    return navigator.clipboard?.writeText(text);
  },
} satisfies IClipboardProvider;

const terminalLinkHandler = {
  activate: (_event: MouseEvent, url: string) => {
    try {
      if (!["file:", "http:", "https:"].includes(new URL(url).protocol)) {
        return;
      }
      window.open(url, "_blank", "noopener,noreferrer");
    } catch {}
  },
  allowNonHttpProtocols: true,
};

const createTerminalAddons = () => [
  new ClipboardAddon(undefined, terminalClipboardProvider),
  createSafeWebglAddon(),
];

const tmuxWindowLabel = (window: TmuxWindow) => {
  if (window.name !== "zsh") {
    return window.name;
  }
  const path = window.panes.find(({ id }) => id === window.activePaneId)?.path;
  return path?.replace(/\/$/, "").split("/").at(-1) ?? window.name;
};

type DiffMode = "base" | "uncommitted";
type PaneView = "conversation" | "terminal";
type LockableScreenOrientation = ScreenOrientation & {
  lock?: (orientation: "landscape") => Promise<void>;
};

const lockDiffLandscape = async () => {
  const orientation = screen.orientation as
    | LockableScreenOrientation
    | undefined;
  if (!orientation?.lock) {
    return false;
  }
  const enteredFullscreen =
    !document.fullscreenElement &&
    Boolean(document.documentElement.requestFullscreen);
  try {
    if (enteredFullscreen) {
      await document.documentElement.requestFullscreen();
    }
    await orientation.lock("landscape");
    return enteredFullscreen;
  } catch {
    if (enteredFullscreen && document.fullscreenElement) {
      await document.exitFullscreen();
    }
    return false;
  }
};

const unlockDiffLandscape = (exitFullscreen: boolean) => {
  screen.orientation?.unlock();
  if (exitFullscreen && document.fullscreenElement) {
    void document.exitFullscreen();
  }
};

const useCompactLandscape = () => {
  const query = "(max-height: 500px) and (orientation: landscape)";
  const [compact, setCompact] = useState(() => matchMedia(query).matches);
  useEffect(() => {
    const media = matchMedia(query);
    const update = () => setCompact(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, [query]);
  return compact;
};

const PaneViewToggle = ({
  compact = false,
  onSelect,
  value,
}: {
  compact?: boolean;
  onSelect: (view: PaneView) => void;
  value: PaneView;
}) => (
  <div
    aria-label="Selected pane view"
    className={[
      "flex shrink-0 rounded border bg-background p-0.5",
      compact ? "ml-auto md:hidden" : undefined,
    ]
      .filter(Boolean)
      .join(" ")}
    role="group"
  >
    <button
      aria-label={compact ? "Show terminal" : undefined}
      aria-pressed={value === "terminal"}
      className={[
        "rounded aria-pressed:bg-panel-muted aria-pressed:font-semibold",
        compact ? "px-2 py-0.5 text-xs" : "px-3 py-1",
      ].join(" ")}
      onClick={() => onSelect("terminal")}
      type="button"
    >
      {compact ? "Term" : "Terminal"}
    </button>
    <button
      aria-label={compact ? "Show Pi conversation" : undefined}
      aria-pressed={value === "conversation"}
      className={[
        "rounded aria-pressed:bg-panel-muted aria-pressed:font-semibold",
        compact ? "px-2 py-0.5 text-xs" : "px-3 py-1",
      ].join(" ")}
      onClick={() => onSelect("conversation")}
      type="button"
    >
      {compact ? "Pi" : "Pi conversation"}
    </button>
  </div>
);

const overmuxDiffThemeName = "overmux-tokyo-night";

registerGitDiffTheme(overmuxDiffThemeName, async () => ({
  ...tokyoNight,
  name: overmuxDiffThemeName,
  tokenColors: [
    ...tokyoNight.tokenColors,
    {
      scope: [
        "source.tsx entity.name.tag",
        "source.js.jsx entity.name.tag",
        "source.tsx entity.name.tag support.class.component",
        "source.js.jsx entity.name.tag support.class.component",
      ],
      settings: { foreground: "#2ac3de" },
    },
  ],
}));

const tokyoNightDiffOptions = {
  diffIndicators: "classic",
  lineDiffType: "word-alt",
  overflow: "wrap",
  theme: overmuxDiffThemeName,
  themeType: "dark",
  unsafeCSS: `
:host {
  --diffs-bg: #1a1b26;
  --diffs-addition-color-override: #3fb950;
  --diffs-deletion-color-override: #f85149;
  --diffs-fg-number-override: #d6ddf9;
  --diffs-fg-number-addition-override: #d6ddf9;
  --diffs-fg-number-deletion-override: #d6ddf9;
  --diffs-bg-context-override: #1a1b26;
  --diffs-bg-context-gutter-override: #1a1b26;
  --diffs-bg-separator-override: #1f3a5f;
  --diffs-bg-addition-emphasis-override: #264e33;
  --diffs-bg-deletion-emphasis-override: #5f2c31;
  --diffs-font-family: "Hack Nerd Font Mono", ui-monospace, monospace;
  --diffs-font-size: var(--om-diff-font-size, 12px);
  --diffs-line-height: var(--om-diff-line-height, 20px);
}
[data-line-type="change-addition"] {
  --diffs-computed-diff-line-bg: #1f302b;
}
[data-line-type="change-deletion"] {
  --diffs-computed-diff-line-bg: #35212a;
}
[data-line-type="change-addition"]:where([data-gutter-buffer], [data-column-number]) {
  --diffs-computed-diff-line-bg: #264e33;
}
[data-line-type="change-deletion"]:where([data-gutter-buffer], [data-column-number]) {
  --diffs-computed-diff-line-bg: #5f2c31;
}
[data-column-number] {
  color: #d6ddf9 !important;
  padding-inline: 1ch !important;
  text-align: center;
}
[data-gutter] [data-column-number],
[data-gutter] [data-gutter-buffer] {
  border-inline-end: 0 !important;
}
[data-indicators="classic"] [data-line] {
  padding-inline-start: 3ch;
}
[data-indicators="classic"] [data-line][data-line-type="change-addition"]::before,
[data-indicators="classic"] [data-line][data-line-type="change-deletion"]::before {
  color: #d6ddf9 !important;
  left: 1ch;
}
[data-separator="line-info"],
[data-separator="line-info"] [data-separator-wrapper],
[data-separator="line-info"] [data-separator-content],
[data-separator="line-info"] [data-expand-button] {
  color: #7aa2f7;
}
[data-content-buffer] {
  background-color: #222431;
  background-image: none;
}
[data-gutter-buffer="buffer"] {
  --diffs-line-bg: #222431;
}
[data-line],
[data-line] * {
  -webkit-user-select: text !important;
  user-select: text !important;
}
[data-diff-span],
[data-diff-span] span {
  color: #d6ddf9 !important;
}
`,
} satisfies GitDiffOptions;

const tokyoNightTheme = {
  background: "#1a1b26",
  black: "#15161e",
  blue: "#7aa2f7",
  brightBlack: "#414868",
  brightBlue: "#7aa2f7",
  brightCyan: "#7dcfff",
  brightGreen: "#9ece6a",
  brightMagenta: "#bb9af7",
  brightRed: "#f7768e",
  brightWhite: "#c0caf5",
  brightYellow: "#e0af68",
  cursor: "#c0caf5",
  cyan: "#7dcfff",
  foreground: "#c0caf5",
  green: "#9ece6a",
  magenta: "#bb9af7",
  red: "#f7768e",
  selectionBackground: "#33467c",
  selectionForeground: "#c0caf5",
  white: "#a9b1d6",
  yellow: "#e0af68",
};

const { useOperation, useResource, useStream } =
  createOvermuxHooks<ServerConfig>();

const windowSelectionCommand = (index: number) => ({
  title: `Select tmux window ${index}`,
});

const commands = defineCommandRegistry<ServerConfig>()({
  ...sourceControlCommands,
  "sourceControl.nextFile": {
    ...sourceControlCommands["sourceControl.nextFile"],
    defaultBindings: ["Tab"],
  },
  "sourceControl.previousFile": {
    ...sourceControlCommands["sourceControl.previousFile"],
    defaultBindings: ["Shift+Tab"],
  },
  "sourceControl.scrollDown": {
    ...sourceControlCommands["sourceControl.scrollDown"],
    defaultBindings: ["Control+D", "Control+ArrowDown"],
  },
  "sourceControl.scrollUp": {
    ...sourceControlCommands["sourceControl.scrollUp"],
    defaultBindings: ["Control+U", "Control+ArrowUp"],
  },
  createWindow: {
    params: z.object({ paneId: z.string() }),
    title: "Create tmux window",
  },
  killPane: {
    params: z.object({ paneId: z.string() }),
    title: "Kill pane",
  },
  killSession: {
    params: z.object({ sessionId: z.string() }),
    title: "Kill session",
  },
  moveWindowLeft: {
    params: z.object({ windowId: z.string() }),
    title: "Move window left",
  },
  moveWindowRight: {
    params: z.object({ windowId: z.string() }),
    title: "Move window right",
  },
  nextWindow: {
    title: "Select next tmux window",
  },
  openBaseDiff: {
    defaultBindings: [
      ["§", "D", "B"],
      ["F12", "D", "B"],
    ],
    title: "Open Base diff",
  },
  openCommandPalette: {
    defaultBindings: [
      ["§", ":"],
      ["F12", ":"],
    ],
    title: "Open command palette",
  },
  openUncommittedDiff: {
    defaultBindings: [
      ["§", "D", "D"],
      ["F12", "D", "D"],
    ],
    title: "Open Local diff",
  },
  openNotifications: {
    defaultBindings: [
      ["§", "N", "N"],
      ["F12", "N", "N"],
    ],
    title: "Open notifications",
  },
  openSessionPicker: {
    defaultBindings: [
      { binding: ["§", "F"], when: { media: "(max-width: 767px)" } },
      { binding: ["F12", "F"], when: { media: "(max-width: 767px)" } },
    ],
    title: "Open session picker",
  },
  previousWindow: {
    title: "Select previous tmux window",
  },
  paneDown: {
    title: "Select pane down",
  },
  paneLeft: {
    title: "Select pane left",
  },
  paneRight: {
    title: "Select pane right",
  },
  paneUp: {
    title: "Select pane up",
  },
  reloadConfig: {
    title: "Reload tmux config",
  },
  splitHorizontal: {
    params: z.object({ paneId: z.string() }),
    title: "Split pane horizontally",
  },
  selectWindow1: windowSelectionCommand(1),
  selectWindow2: windowSelectionCommand(2),
  selectWindow3: windowSelectionCommand(3),
  selectWindow4: windowSelectionCommand(4),
  selectWindow5: windowSelectionCommand(5),
  selectWindow6: windowSelectionCommand(6),
  selectWindow7: windowSelectionCommand(7),
  selectWindow8: windowSelectionCommand(8),
  selectWindow9: windowSelectionCommand(9),
  selectWindow10: windowSelectionCommand(10),
  splitVertical: {
    params: z.object({ paneId: z.string() }),
    title: "Split pane vertically",
  },
});

const selectionFromUrl = (name: string) =>
  new URLSearchParams(location.search).get(name);

const writeSelection = (name: string, value: string) => {
  const url = new URL(location.href);
  if (url.searchParams.get(name) === value) {
    return;
  }
  url.searchParams.set(name, value);
  history.replaceState({}, "", url);
};

const focusTerminal = () =>
  requestAnimationFrame(() =>
    document
      .querySelector<HTMLElement>(
        "[data-om-tmux-terminal] .xterm-helper-textarea",
      )
      ?.focus(),
  );

const notificationChannels = ["all", "agent", "github"] as const;
type NotificationChannel = (typeof notificationChannels)[number];
type NotificationRoute = { channel: NotificationChannel; id?: string };

type NavigationState = { notificationReturnTo?: string };

const navigate = (
  path: string,
  replace = false,
  state: NavigationState = history.state ?? {},
) => {
  history[replace ? "replaceState" : "pushState"](state, "", path);
  window.dispatchEvent(new PopStateEvent("popstate"));
};

const openNotifications = () =>
  navigate("/notifications/all", false, {
    notificationReturnTo: `${location.pathname}${location.search}`,
  });

const closeNotifications = () => {
  const state = (history.state ?? {}) as NavigationState;
  navigate(state.notificationReturnTo ?? "/", true, {});
};

const useRoutePath = () => {
  const [path, setPath] = useState(() => location.pathname);
  useEffect(() => {
    const update = () => setPath(location.pathname);
    window.addEventListener("popstate", update);
    return () => window.removeEventListener("popstate", update);
  }, []);
  return path;
};

const notificationRoute = (path: string): NotificationRoute | undefined => {
  const parts = path.split("/").filter(Boolean);
  if (parts[0] !== "notifications" || parts.length > 3) {
    return undefined;
  }
  const channel = notificationChannels.find(
    (candidate) => candidate === parts[1],
  );
  return channel
    ? { channel, ...(parts[2] ? { id: parts[2] } : {}) }
    : undefined;
};

const localDateTime = (timestamp: string) =>
  new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "medium",
  }).format(new Date(timestamp));

const sameDay = (left: Date, right: Date) =>
  left.getFullYear() === right.getFullYear() &&
  left.getMonth() === right.getMonth() &&
  left.getDate() === right.getDate();

const recency = (timestamp: string, now: number) => {
  const sentAt = new Date(timestamp);
  const current = new Date(now);
  const elapsed = Math.max(0, now - sentAt.getTime());
  const minutes = Math.floor(elapsed / 60_000);
  const time = new Intl.DateTimeFormat(undefined, {
    timeStyle: "short",
  }).format(sentAt);
  if (minutes < 1) {
    return "now";
  }
  if (minutes < 60) {
    return `${minutes}m`;
  }
  if (sameDay(sentAt, current) && minutes < 6 * 60) {
    return `${Math.floor(minutes / 60)}h`;
  }
  if (sameDay(sentAt, current)) {
    return time;
  }
  const yesterday = new Date(now);
  yesterday.setDate(current.getDate() - 1);
  if (sameDay(sentAt, yesterday)) {
    return "Yesterday";
  }
  if (elapsed < 7 * 24 * 60 * 60_000) {
    return new Intl.DateTimeFormat(undefined, { weekday: "short" }).format(
      sentAt,
    );
  }
  return new Intl.DateTimeFormat(undefined, { dateStyle: "medium" }).format(
    sentAt,
  );
};

const useCurrentMinute = () => {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 60_000);
    return () => clearInterval(timer);
  }, []);
  return now;
};

const useTmuxSelection = (state: TmuxState) => {
  const [sessionId, setSessionId] = useState(() => selectionFromUrl("session"));
  const session =
    state.hierarchy.sessions.find((candidate) => candidate.id === sessionId) ??
    state.hierarchy.sessions[0];
  const window = session?.windows.find(
    (candidate) => candidate.id === session.activeWindowId,
  );
  useEffect(() => {
    if (!session) {
      return;
    }
    if (session.id !== sessionId) {
      setSessionId(session.id);
    }
    writeSelection("session", session.id);
  }, [session, sessionId]);
  useEffect(() => {
    if (window) {
      writeSelection("window", window.id);
    }
  }, [window]);
  const selectSession = (next: TmuxSession) => {
    if (next.id !== sessionId) {
      setSessionId(next.id);
    }
    writeSelection("session", next.id);
  };
  const selectSessionId = (nextSessionId: string) => {
    const next = state.hierarchy.sessions.find(
      (candidate) => candidate.id === nextSessionId,
    );
    if (next) {
      selectSession(next);
    }
  };
  return { selectSession, selectSessionId, session, window };
};

const SessionPicker = ({
  close,
  selectSessionId,
}: {
  close: () => void;
  selectSessionId: (sessionId: string) => void;
}) => {
  const picker = useResource({ id: "richardTmuxSessionPicker" });
  const clear = useOperation({ id: "sessionPickerClear" });
  const connect = useOperation({ id: "sessionPickerConnect" });
  const create = useOperation({ id: "sessionPickerCreate" });
  const kill = useOperation({ id: "sessionPickerKill" });
  const quarantine = useOperation({ id: "sessionPickerQuarantine" });
  const revive = useOperation({ id: "sessionPickerRevive" });
  const actions = { clear, connect, create, kill, quarantine, revive };
  const [manageEntry, setManageEntry] = useState<TmuxSessionPickerEntry>();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const entries = picker.data?.entries ?? [];
  useEffect(
    () =>
      setSelectedIndex((index) =>
        Math.max(0, Math.min(index, Math.max(entries.length - 1, 0))),
      ),
    [entries.length],
  );
  const run = async (
    operation: keyof typeof actions,
    entry: TmuxSessionPickerEntry,
  ) => {
    if (!picker.data) {
      return;
    }
    const result = await actions[operation].mutateAsync({
      ref: entry.ref,
      revision: picker.data.revision,
    });
    if (result.outcome === "success" && result.sessionId) {
      selectSessionId(result.sessionId);
      close();
    }
    picker.refetch();
  };
  const openEntry = (entry: TmuxSessionPickerEntry) => {
    if (entry.sessionId) {
      selectSessionId(entry.sessionId);
      close();
      return;
    }
    const operation = entry.actions.find((action) =>
      ["connect", "create", "revive"].includes(action),
    );
    if (operation) {
      void run(operation, entry);
    }
  };
  const selectEntry = () => {
    const entry = entries[selectedIndex];
    if (entry) {
      openEntry(entry);
    }
  };
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (manageEntry) {
        if (event.key === "Escape") {
          event.preventDefault();
          event.stopPropagation();
          setManageEntry(undefined);
        }
        return;
      }
      if (event.key === "Escape") {
        event.preventDefault();
        event.stopPropagation();
        close();
        return;
      }
      if (
        !["ArrowDown", "ArrowUp", "Enter"].includes(event.key) ||
        (event.key === "Enter" && event.target instanceof HTMLButtonElement)
      ) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      if (event.key === "ArrowDown") {
        setSelectedIndex((index) =>
          Math.min(index + 1, Math.max(entries.length - 1, 0)),
        );
      }
      if (event.key === "ArrowUp") {
        setSelectedIndex((index) => Math.max(index - 1, 0));
      }
      if (event.key === "Enter") {
        selectEntry();
      }
    };
    window.addEventListener("keydown", handleKeyDown, true);
    return () => window.removeEventListener("keydown", handleKeyDown, true);
  }, [close, entries.length, manageEntry, selectEntry]);
  return (
    <section
      autoFocus
      className="absolute inset-0 z-[1000] overflow-y-auto overflow-x-hidden bg-background p-3 md:fixed md:inset-4 md:rounded md:border md:p-4"
      tabIndex={-1}
    >
      <header className="mb-3 flex items-start justify-between gap-3">
        <h2 className="min-w-0 font-semibold">Tmux sessions and worktrees</h2>
        <Button
          className="shrink-0"
          onClick={close}
          size="sm"
          variant="outline"
        >
          Close
        </Button>
      </header>
      <div className="grid min-w-0 gap-2">
        {entries.map((entry, index) => (
          <Item
            className={[
              index === selectedIndex
                ? "border-accent bg-panel-muted"
                : undefined,
              ["inactive", "quarantined"].includes(entry.state)
                ? "opacity-50"
                : undefined,
            ]
              .filter(Boolean)
              .join(" ")}
            key={entry.ref}
          >
            <button
              aria-label={`Open ${entry.label}`}
              className="min-w-0 flex-1 self-stretch rounded-l-lg p-2 text-left hover:bg-panel-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
              onClick={() => {
                setSelectedIndex(index);
                openEntry(entry);
              }}
              onFocus={() => setSelectedIndex(index)}
              type="button"
            >
              <ItemContent>
                <ItemTitle className="truncate">{entry.label}</ItemTitle>
              </ItemContent>
            </button>
            {entry.actions.some(
              (operation) => operation === "kill" || operation === "quarantine",
            ) ? (
              <ItemActions className="p-1 pl-0">
                <Button
                  aria-label={`Manage ${entry.label}`}
                  className="text-foreground/60"
                  onClick={() => setManageEntry(entry)}
                  size="icon"
                  title="Manage session"
                  variant="ghost"
                >
                  <Trash2 aria-hidden="true" className="size-4" />
                </Button>
              </ItemActions>
            ) : null}
          </Item>
        ))}
      </div>
      <Dialog
        onOpenChange={(open) => {
          if (!open) {
            setManageEntry(undefined);
          }
        }}
        open={Boolean(manageEntry)}
      >
        {manageEntry ? (
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Manage tmux session</DialogTitle>
              <DialogDescription>{manageEntry.label}</DialogDescription>
            </DialogHeader>
            <DialogFooter>
              {(["quarantine", "kill"] as const)
                .filter((operation) => manageEntry.actions.includes(operation))
                .map((operation) => (
                  <Button
                    className="capitalize"
                    key={operation}
                    onClick={() => {
                      setManageEntry(undefined);
                      void run(operation, manageEntry);
                    }}
                    variant={operation === "kill" ? "destructive" : "outline"}
                  >
                    {operation}
                  </Button>
                ))}
            </DialogFooter>
          </DialogContent>
        ) : null}
      </Dialog>
    </section>
  );
};

type TerminalModifier = "alt" | "ctrl";
type TerminalModifiers = Record<TerminalModifier, boolean>;
type TerminalAccessoryKey = { input: string; label: string; name: string };

const emptyTerminalModifiers: TerminalModifiers = { alt: false, ctrl: false };
const terminalAccessoryKeys: readonly TerminalAccessoryKey[] = [
  { input: "\t", label: "Tab", name: "Tab" },
  { input: "/", label: "/", name: "Slash" },
  { input: "\\", label: "\\", name: "Backslash" },
  { input: "\u001b[D", label: "←", name: "Left arrow" },
  { input: "\u001b[B", label: "↓", name: "Down arrow" },
  { input: "\u001b[A", label: "↑", name: "Up arrow" },
  { input: "\u001b[C", label: "→", name: "Right arrow" },
];

const controlCharacter = (input: string) => {
  const character = input[0];
  if (!character) {
    return input;
  }
  const code = character.toUpperCase().charCodeAt(0);
  if (code >= 64 && code <= 95) {
    return String.fromCharCode(code & 31) + input.slice(1);
  }
  if (character === "/") {
    return "\u001f" + input.slice(1);
  }
  if (character === "?") {
    return "\u007f" + input.slice(1);
  }
  return character === " " ? "\0" + input.slice(1) : input;
};

const applyTerminalModifiers = (
  input: string,
  modifiers: TerminalModifiers,
) => {
  const arrow =
    input.length === 3 && input.startsWith("\u001b[") ? input[2] : "";
  if (arrow && "ABCD".includes(arrow) && (modifiers.alt || modifiers.ctrl)) {
    return `\u001b[1;${1 + Number(modifiers.alt) * 2 + Number(modifiers.ctrl) * 4}${arrow}`;
  }
  const controlInput = modifiers.ctrl ? controlCharacter(input) : input;
  return modifiers.alt ? `\u001b${controlInput}` : controlInput;
};

const keepTerminalFocused = (event: ReactPointerEvent<HTMLButtonElement>) =>
  event.preventDefault();

const MobileTerminalKeys = ({
  active,
  terminalRef,
}: {
  active: boolean;
  terminalRef: { current: XtermTerminalHandle | null };
}) => {
  const [modifiers, setModifiers] = useState(emptyTerminalModifiers);
  const send = (input: string) => {
    if (!active) {
      return;
    }
    terminalRef.current?.input(applyTerminalModifiers(input, modifiers));
    setModifiers(emptyTerminalModifiers);
    terminalRef.current?.focus();
  };
  const toggleModifier = (modifier: TerminalModifier) => {
    setModifiers((current) => ({
      ...current,
      [modifier]: !current[modifier],
    }));
    terminalRef.current?.focus();
  };
  return (
    <div
      aria-label="Terminal keys"
      className="om-tmux-terminal-keys"
      role="toolbar"
    >
      <button
        aria-label="Escape"
        className="om-tmux-terminal-key"
        onClick={() => send("\u001b")}
        onPointerDown={keepTerminalFocused}
        type="button"
      >
        Esc
      </button>
      {(["alt", "ctrl"] as const).map((modifier) => (
        <button
          aria-label={modifier === "alt" ? "Alt" : "Ctrl"}
          aria-pressed={modifiers[modifier]}
          className="om-tmux-terminal-key"
          data-om-active={modifiers[modifier] ? "true" : "false"}
          key={modifier}
          onClick={() => toggleModifier(modifier)}
          onPointerDown={keepTerminalFocused}
          type="button"
        >
          {modifier === "alt" ? "Alt" : "Ctrl"}
        </button>
      ))}
      {terminalAccessoryKeys.map((key) => (
        <button
          aria-label={key.name}
          className="om-tmux-terminal-key"
          key={key.name}
          onClick={() => send(key.input)}
          onPointerDown={keepTerminalFocused}
          type="button"
        >
          {key.label}
        </button>
      ))}
    </div>
  );
};

const TerminalPane = ({
  active = true,
  onClose,
  onError,
  onSessionChange,
  sessionId,
}: {
  active?: boolean;
  onClose: () => Promise<void>;
  onError: (message: string) => void;
  onSessionChange: (sessionId: string) => void;
  sessionId: string;
}) => {
  const stream = useStream({ id: "tmuxTerminal" });
  const terminalRef = useRef<XtermTerminalHandle>(null);
  return (
    <div
      className="om-terminal-pane flex min-h-0 flex-1 flex-col"
      data-om-active={active ? "true" : "false"}
    >
      <TmuxXterm
        active={active}
        containerClassName="om-tmux-hide-mobile-status"
        createAddons={createTerminalAddons}
        onClose={onClose}
        onError={(error) => onError(error.message)}
        onSessionChange={onSessionChange}
        options={{
          fontFamily: '"Hack Nerd Font Mono", ui-monospace, monospace',
          linkHandler: terminalLinkHandler,
          scrollback: 1_000,
          theme: tokyoNightTheme,
        }}
        ref={terminalRef}
        sessionId={sessionId}
        stream={stream}
      />
      <MobileTerminalKeys active={active} terminalRef={terminalRef} />
    </div>
  );
};

const PiPane = ({ active, agentId }: { active: boolean; agentId: string }) => {
  const conversation = useStream({
    id: "piConversation",
    input: { agentId },
  });
  const sendMessage = useOperation({ id: "sendPiMessage" });
  const stop = useOperation({ id: "stopPiAgent" });
  const setModel = useOperation({ id: "setPiModel" });
  const setThinkingLevel = useOperation({ id: "setPiThinkingLevel" });
  return (
    <PiConversation
      autoFocus={active}
      classNames={{ status: "max-md:hidden" }}
      conversation={conversation}
      sendMessage={(message) =>
        sendMessage.mutateAsync({ agentId, ...message })
      }
      setModel={(model) =>
        setModel.mutateAsync({ agentId, ...model }).then(() => undefined)
      }
      setThinkingLevel={(level) =>
        setThinkingLevel.mutateAsync({ agentId, level }).then(() => undefined)
      }
      stop={() => stop.mutateAsync({ agentId }).then(() => undefined)}
    />
  );
};

const PaneViewport = ({
  agentId,
  onClose,
  onError,
  onSessionChange,
  paneView,
  selectPaneView,
  sessionId,
}: {
  agentId?: string;
  onClose: () => Promise<void>;
  onError: (message: string) => void;
  onSessionChange: (sessionId: string) => void;
  paneView: PaneView;
  selectPaneView: (view: PaneView) => void;
  sessionId: string;
}) => (
  <div className="relative min-h-0 flex-1">
    {agentId ? (
      <div className="absolute top-2 right-3 z-20 hidden text-sm shadow md:block">
        <PaneViewToggle onSelect={selectPaneView} value={paneView} />
      </div>
    ) : null}
    <div
      aria-hidden={paneView !== "terminal"}
      className={
        paneView === "terminal"
          ? "absolute inset-0 flex min-w-0"
          : "pointer-events-none invisible absolute inset-0 flex min-w-0"
      }
    >
      <TerminalPane
        active={paneView === "terminal"}
        onClose={onClose}
        onError={onError}
        onSessionChange={onSessionChange}
        sessionId={sessionId}
      />
    </div>
    {agentId && paneView === "conversation" ? (
      <div className="absolute inset-0 flex min-w-0">
        <PiPane active agentId={agentId} />
      </div>
    ) : null}
  </div>
);

type GitChange = GitSourceControl["changes"][number];
type ChangeSelection = Pick<GitChange, "area" | "path">;
type SelectionsByPath = Partial<
  Record<string, Partial<Record<DiffMode, ChangeSelection>>>
>;

const initialChange = (snapshot?: GitSourceControl) =>
  orderedChanges(snapshot)[0];

const sameChange = (left?: ChangeSelection, right?: ChangeSelection) =>
  left?.area === right?.area && left?.path === right?.path;

const selectedChange = ({
  selection,
  snapshot,
}: {
  selection?: ChangeSelection;
  snapshot?: GitSourceControl;
}) =>
  (selection
    ? snapshot?.changes.find((change) => sameChange(change, selection))
    : undefined) ?? initialChange(snapshot);

const useSourceControlData = ({
  activeComparison,
  path,
}: {
  activeComparison?: DiffMode;
  path?: string;
}) => {
  const baseSnapshot = useResource({
    id: "gitSourceControl",
    input: path ? { comparison: "base", path } : skipToken,
  });
  const uncommittedSnapshot = useResource({
    id: "gitSourceControl",
    input: path ? { comparison: "uncommitted", path } : skipToken,
  });
  const stage = useOperation({ id: "stage" });
  const unstage = useOperation({ id: "unstage" });
  const discard = useOperation({ id: "discard" });
  const [selections, setSelections] = useState<SelectionsByPath>({});
  const baseSelectedChange = selectedChange({
    selection: path ? selections[path]?.base : undefined,
    snapshot: baseSnapshot?.data,
  });
  const uncommittedSelectedChange = selectedChange({
    selection: path ? selections[path]?.uncommitted : undefined,
    snapshot: uncommittedSnapshot?.data,
  });
  const selectChange = useCallback(
    (comparison: DiffMode, change: GitChange) => {
      if (!path) {
        return;
      }
      setSelections((current) => ({
        ...current,
        [path]: {
          ...current[path],
          [comparison]: { area: change.area, path: change.path },
        },
      }));
    },
    [path],
  );
  const mutate = useCallback(
    async (operation: "discard" | "stage" | "unstage", change: GitChange) => {
      const snapshot = uncommittedSnapshot?.data;
      if (!path || !snapshot) {
        return;
      }
      await { discard, stage, unstage }[operation].mutateAsync({
        changes: [
          {
            area: change.area === "conflict" ? undefined : change.area,
            path: change.path,
          },
        ],
        expectedRevision: snapshot.revision,
        path,
      });
      uncommittedSnapshot?.refetch();
    },
    [discard, path, stage, uncommittedSnapshot, unstage],
  );
  const branch =
    uncommittedSnapshot?.data?.comparison === "uncommitted"
      ? uncommittedSnapshot.data.branch.name
      : undefined;
  const base = {
    branch,
    comparison: "base" as const,
    path,
    onDiscard: undefined,
    onSelectChange: (change: GitChange) => selectChange("base", change),
    onStage: undefined,
    onUnstage: undefined,
    selectedChange: baseSelectedChange,
    snapshot: baseSnapshot,
  };
  const uncommitted = {
    branch,
    comparison: "uncommitted" as const,
    path,
    onDiscard: (change: GitChange) => void mutate("discard", change),
    onSelectChange: (change: GitChange) => selectChange("uncommitted", change),
    onStage: (change: GitChange) => void mutate("stage", change),
    onUnstage: (change: GitChange) => void mutate("unstage", change),
    selectedChange: uncommittedSelectedChange,
    snapshot: uncommittedSnapshot,
  };
  return {
    active:
      activeComparison === "base"
        ? base
        : activeComparison === "uncommitted"
          ? uncommitted
          : undefined,
    base,
    uncommitted,
  };
};

type SourceControlData = NonNullable<
  ReturnType<typeof useSourceControlData>["active"]
>;

type SourceControlProps = {
  close: () => void;
  data: SourceControlData;
};

type TouchPoint = { x: number; y: number };
type PinchStart = { distance: number; fontSize: number };

const diffFontSize = {
  desktop: 12,
  maximum: 16,
  minimum: 8,
  mobile: 10,
};

const touchDistance = (points: TouchPoint[]) => {
  const [first, second] = points;
  if (!first || !second) {
    return 0;
  }
  return Math.hypot(second.x - first.x, second.y - first.y);
};

const isDiffPointer = (target: EventTarget) =>
  target instanceof Element &&
  Boolean(target.closest(".om-source-control-diff"));

const SourceControl = ({ close, data }: SourceControlProps) => {
  const compactLandscape = useCompactLandscape();
  const isMobile = useIsMobile();
  const initialFontSize =
    compactLandscape || isMobile ? diffFontSize.mobile : diffFontSize.desktop;
  const folderName = data.path?.replace(/\/$/, "").split("/").at(-1);
  const visibleBranch = data.branch === folderName ? undefined : data.branch;
  const [discardConfirmation, setDiscardConfirmation] = useState<GitChange>();
  const [fontSize, setFontSize] = useState(initialFontSize);
  const touchPoints = useRef(new Map<number, TouchPoint>());
  const pinchStart = useRef<PinchStart | undefined>(undefined);
  const commandEntries = useCommands();
  const nextFile = commandEntries.find(
    ({ id }) => id === "sourceControl.nextFile",
  );
  const previousFile = commandEntries.find(
    ({ id }) => id === "sourceControl.previousFile",
  );
  const startPinch = (event: ReactPointerEvent<HTMLElement>) => {
    if (event.pointerType !== "touch" || !isDiffPointer(event.target)) {
      return;
    }
    touchPoints.current.set(event.pointerId, {
      x: event.clientX,
      y: event.clientY,
    });
    if (touchPoints.current.size !== 2) {
      return;
    }
    event.preventDefault();
    pinchStart.current = {
      distance: touchDistance([...touchPoints.current.values()]),
      fontSize,
    };
  };
  const movePinch = (event: ReactPointerEvent<HTMLElement>) => {
    if (!touchPoints.current.has(event.pointerId)) {
      return;
    }
    touchPoints.current.set(event.pointerId, {
      x: event.clientX,
      y: event.clientY,
    });
    const start = pinchStart.current;
    if (!start || touchPoints.current.size !== 2 || start.distance === 0) {
      return;
    }
    event.preventDefault();
    const next =
      start.fontSize *
      (touchDistance([...touchPoints.current.values()]) / start.distance);
    setFontSize(
      Math.round(
        Math.max(diffFontSize.minimum, Math.min(diffFontSize.maximum, next)) *
          4,
      ) / 4,
    );
  };
  const endPinch = (event: ReactPointerEvent<HTMLElement>) => {
    touchPoints.current.delete(event.pointerId);
    if (touchPoints.current.size < 2) {
      pinchStart.current = undefined;
    }
  };
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (discardConfirmation) {
        event.preventDefault();
        event.stopPropagation();
        if (event.key.toLowerCase() === "y") {
          data.onDiscard?.(discardConfirmation);
          setDiscardConfirmation(undefined);
        } else if (event.key.toLowerCase() === "n" || event.key === "Escape") {
          setDiscardConfirmation(undefined);
        }
        return;
      }
      const selectedChange = data.selectedChange;
      if (
        event.key === "s" &&
        !event.altKey &&
        !event.ctrlKey &&
        !event.metaKey &&
        selectedChange
      ) {
        const mutate =
          selectedChange.area === "staged" ? data.onUnstage : data.onStage;
        if (!mutate) {
          return;
        }
        event.preventDefault();
        event.stopPropagation();
        mutate(selectedChange);
        return;
      }
      if (
        event.key === "X" &&
        !event.altKey &&
        !event.ctrlKey &&
        !event.metaKey &&
        selectedChange?.area === "unstaged" &&
        data.onDiscard
      ) {
        event.preventDefault();
        event.stopPropagation();
        setDiscardConfirmation(selectedChange);
        return;
      }
      const treeFocused = document.activeElement?.matches(
        ".om-git-change-tree, .om-source-control-sidebar",
      );
      if (
        treeFocused &&
        ["ArrowDown", "ArrowUp"].includes(event.key) &&
        !event.altKey &&
        !event.ctrlKey &&
        !event.metaKey
      ) {
        const command = event.key === "ArrowDown" ? nextFile : previousFile;
        if (!command?.enabled) {
          return;
        }
        event.preventDefault();
        event.stopPropagation();
        void command.execute();
        return;
      }
      if (
        event.key === "Tab" &&
        !event.altKey &&
        !event.ctrlKey &&
        !event.metaKey
      ) {
        const command = event.shiftKey ? previousFile : nextFile;
        if (!command?.enabled) {
          return;
        }
        event.preventDefault();
        event.stopPropagation();
        void command.execute();
        return;
      }
      const closeRequested =
        event.key === "Escape" ||
        (event.key === "q" &&
          !event.altKey &&
          !event.ctrlKey &&
          !event.metaKey);
      if (!closeRequested) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      close();
    };
    window.addEventListener("keydown", handleKeyDown, true);
    return () => window.removeEventListener("keydown", handleKeyDown, true);
  }, [close, data, nextFile, previousFile]);
  return (
    <section
      className="source-control-screen fixed inset-0 z-40 grid min-h-0 grid-rows-[auto_minmax(0,1fr)] overflow-hidden bg-background p-4"
      data-comparison={data.comparison}
      onDoubleClickCapture={(event) => {
        if (isDiffPointer(event.target)) {
          setFontSize(initialFontSize);
        }
      }}
      onPointerCancelCapture={endPinch}
      onPointerDownCapture={startPinch}
      onPointerMoveCapture={movePinch}
      onPointerUpCapture={endPinch}
      style={
        {
          "--om-diff-font-size": `${fontSize}px`,
          "--om-diff-line-height": `${Math.round((fontSize * 5) / 3)}px`,
          "--om-main-header-font-size": `${fontSize}px`,
          "--om-main-header-line-height": `${Math.round((fontSize * 4) / 3)}px`,
          "--om-close-button-size": `${Math.round((fontSize * 8) / 3)}px`,
          "--om-close-icon-size": `${fontSize * 2}px`,
        } as CSSProperties
      }
    >
      <header className="mb-3 flex items-center justify-between gap-4">
        <div className="flex min-w-0 items-center gap-2 font-semibold">
          <h2 className="source-control-file-path min-w-0 truncate">
            {data.path}
          </h2>
          {visibleBranch ? (
            <Badge className="source-control-branch-badge max-w-64 shrink-0 truncate">
              {visibleBranch}
            </Badge>
          ) : null}
          <span className="shrink-0">
            · {data.comparison === "uncommitted" ? "Local diff" : "Base diff"}
          </span>
        </div>
        <button
          aria-label="Close diff"
          className="flex size-12 shrink-0 items-center justify-center text-3xl leading-none"
          onClick={close}
          type="button"
        >
          ×
        </button>
      </header>
      <SourceControlView
        classNames={{
          diff: "min-w-0 overflow-auto",
          root: "min-h-0 min-w-0",
          sidebar: "h-full min-w-0",
        }}
        commandHandles={commands}
        defaultSidebarWidth={compactLandscape ? 180 : undefined}
        diffOptions={tokyoNightDiffOptions}
        diffStyle="split"
        flattenEmptyDirectories
        error={data.snapshot?.error}
        loading={data.snapshot?.status === "pending"}
        maxSidebarWidth={compactLandscape ? 280 : undefined}
        minSidebarWidth={compactLandscape ? 160 : undefined}
        sourceControl={data.snapshot?.data}
        onDiscard={data.onDiscard}
        onSelectChange={data.onSelectChange}
        onStage={data.onStage}
        onUnstage={data.onUnstage}
        selectedChange={data.selectedChange}
      />
      {discardConfirmation ? (
        <div
          className="fixed inset-0 z-50 grid place-items-center bg-black/60 p-4"
          role="presentation"
        >
          <section
            aria-labelledby="discard-confirmation-title"
            className="w-full max-w-lg rounded border bg-background p-5 shadow-xl"
            aria-modal="true"
            role="dialog"
          >
            <h3 className="font-semibold" id="discard-confirmation-title">
              Discard unstaged changes?
            </h3>
            <p className="source-control-file-path my-4 break-all">
              {discardConfirmation.path}
            </p>
            <p className="text-sm text-foreground/70">
              Press y to discard or n to cancel.
            </p>
            <div className="mt-5 flex justify-end gap-2">
              <Button
                onClick={() => setDiscardConfirmation(undefined)}
                variant="outline"
              >
                Cancel (n)
              </Button>
              <Button
                onClick={() => {
                  data.onDiscard?.(discardConfirmation);
                  setDiscardConfirmation(undefined);
                }}
                variant="destructive"
              >
                Discard (y)
              </Button>
            </div>
          </section>
        </div>
      ) : null}
    </section>
  );
};

const SourceControlPortal = (props: SourceControlProps) =>
  createPortal(<SourceControl {...props} />, document.body);

const CommandPalette = ({ close }: { close: () => void }) => {
  const commandEntries = useCommands();
  return (
    <section className="fixed inset-4 z-50 overflow-auto rounded border bg-background p-4">
      <header className="mb-3 flex justify-between">
        <h2 className="font-semibold">Commands</h2>
        <button onClick={close} type="button">
          Close
        </button>
      </header>
      {commandEntries.map(({ bindings, enabled, execute, id, title }) => (
        <button
          className="flex w-full justify-between rounded p-2 text-left hover:bg-panel-muted"
          disabled={!enabled}
          key={id}
          onClick={() => void execute()}
          type="button"
        >
          <span>{title}</span>
          <span>
            {bindings
              .map((binding) =>
                Array.isArray(binding) ? binding.join(" ") : binding,
              )
              .join(", ")}
          </span>
        </button>
      ))}
    </section>
  );
};

const SettingsApp = () => (
  <main className="flex h-dvh min-h-0 flex-col bg-background text-foreground">
    <header className="flex shrink-0 items-center gap-3 border-b px-4 py-3">
      <button
        className="rounded px-2 py-1 text-sm hover:bg-panel-muted"
        onClick={() => navigate("/")}
        type="button"
      >
        Back
      </button>
      <h1 className="font-semibold">Settings</h1>
    </header>
    <section className="p-4">
      <h2 className="mb-2 font-medium">Notifications</h2>
      <div data-om-background-notifications-slot="" />
    </section>
  </main>
);

const NotificationsApp = ({ route }: { route: NotificationRoute }) => {
  const notifications = useResource({
    id: "notifications",
    input: { limit: 500 },
  });
  const now = useCurrentMinute();
  const items = notifications.data?.items ?? [];
  const counts = notifications.data?.totals ?? {
    agent: 0,
    all: 0,
    github: 0,
  };
  const visible =
    route.channel === "all"
      ? items
      : items.filter((item) => item.topic === route.channel);
  const selected = visible.find((item) => item.id === route.id);
  const selectChannel = (channel: NotificationChannel) =>
    navigate(`/notifications/${channel}`);
  const selectNotification = (notification: StoredNotification) =>
    navigate(`/notifications/${route.channel}/${notification.id}`);
  return (
    <main
      className="flex h-dvh min-h-0 flex-col bg-background text-foreground"
      data-om-background-notifications-slotted=""
    >
      <header className="flex shrink-0 items-center justify-between border-b px-4 py-3">
        <h1 className="font-semibold">Notifications</h1>
        <button
          aria-label="Close notifications"
          className="flex size-10 items-center justify-center rounded text-2xl leading-none hover:bg-panel-muted"
          onClick={closeNotifications}
          type="button"
        >
          ×
        </button>
      </header>
      <div className="grid min-h-0 flex-1 grid-cols-1 grid-rows-[auto_minmax(0,1fr)] md:grid-cols-[13rem_minmax(18rem,0.8fr)_minmax(0,1.5fr)] md:grid-rows-1">
        <aside className="shrink-0 border-b p-2 md:min-h-0 md:border-r md:border-b-0">
          <nav
            aria-label="Notification channels"
            className="flex gap-1 overflow-x-auto md:flex-col"
          >
            {notificationChannels.map((channel) => (
              <button
                aria-current={route.channel === channel ? "page" : undefined}
                className="flex shrink-0 items-center justify-between gap-4 rounded px-3 py-2 text-left text-sm hover:bg-panel-muted aria-[current=page]:bg-panel-muted aria-[current=page]:font-semibold"
                key={channel}
                onClick={() => selectChannel(channel)}
                type="button"
              >
                <span className="capitalize">{channel}</span>
                <span className="text-foreground/55">{counts[channel]}</span>
              </button>
            ))}
          </nav>
        </aside>
        <section
          className={[
            "min-h-0 flex-col border-r",
            route.id ? "hidden md:flex" : "flex",
          ].join(" ")}
        >
          <header className="hidden shrink-0 items-center justify-between border-b px-4 py-3 md:flex">
            <h2 className="font-medium capitalize">{route.channel}</h2>
            <span className="text-sm text-foreground/55">
              {visible.length} shown
            </span>
          </header>
          <div className="min-h-0 overflow-y-auto">
            {notifications.status === "pending" ? (
              <p className="p-4 text-sm text-foreground/60">
                Loading notifications…
              </p>
            ) : null}
            {notifications.status === "error" ? (
              <p className="p-4 text-sm text-red-300" role="alert">
                {notifications.error.message}
              </p>
            ) : null}
            {notifications.status === "success" && !visible.length ? (
              <p className="p-4 text-sm text-foreground/60">
                No notifications in this channel.
              </p>
            ) : null}
            {visible.map((notification) => (
              <button
                aria-current={
                  selected?.id === notification.id ? "true" : undefined
                }
                className="flex w-full flex-col gap-1 border-b px-4 py-3 text-left hover:bg-panel-muted aria-[current=true]:bg-panel-muted"
                key={notification.id}
                onClick={() => selectNotification(notification)}
                type="button"
              >
                <span className="flex items-start justify-between gap-3">
                  <span className="line-clamp-1 font-medium">
                    {notification.title}
                  </span>
                  <time
                    className="shrink-0 text-xs text-foreground/55"
                    dateTime={notification.sentAt}
                    title={localDateTime(notification.sentAt)}
                  >
                    {recency(notification.sentAt, now)}
                  </time>
                </span>
                <span className="line-clamp-2 text-sm text-foreground/65">
                  {notification.body}
                </span>
                {route.channel === "all" ? (
                  <span className="text-xs capitalize text-foreground/50">
                    {notification.topic}
                  </span>
                ) : null}
              </button>
            ))}
          </div>
        </section>
        <section
          className={[
            "min-h-0 flex-col",
            route.id ? "flex" : "hidden md:flex",
          ].join(" ")}
        >
          {route.id && notifications.status === "pending" ? (
            <p className="p-6 text-sm text-foreground/60">
              Loading notification…
            </p>
          ) : route.id && notifications.status === "error" ? (
            <p className="p-6 text-sm text-red-300" role="alert">
              {notifications.error.message}
            </p>
          ) : selected ? (
            <>
              <header className="flex shrink-0 items-start justify-between gap-4 border-b px-4 py-3">
                <div className="min-w-0">
                  <p className="text-xs font-medium uppercase tracking-wide text-foreground/55">
                    {selected.topic}
                  </p>
                  <h2 className="mt-1 text-lg font-semibold">
                    {selected.title}
                  </h2>
                  <time
                    className="mt-2 block text-sm text-foreground/60"
                    dateTime={selected.sentAt}
                  >
                    {localDateTime(selected.sentAt)}
                  </time>
                </div>
                <button
                  className="shrink-0 rounded px-2 py-1 text-sm hover:bg-panel-muted md:hidden"
                  onClick={() => navigate(`/notifications/${route.channel}`)}
                  type="button"
                >
                  Back
                </button>
              </header>
              <article className="min-h-0 flex-1 overflow-y-auto px-4 py-5">
                <p className="whitespace-pre-wrap break-words leading-7 text-foreground/85">
                  {selected.body}
                </p>
                {selected.link ? (
                  <a
                    className="mt-6 inline-flex rounded border px-3 py-2 text-sm font-medium hover:bg-panel-muted"
                    href={selected.link}
                  >
                    Open link
                  </a>
                ) : null}
              </article>
            </>
          ) : route.id ? (
            <div className="grid min-h-0 flex-1 place-items-center p-6 text-center">
              <div>
                <p className="font-medium">Notification not found</p>
                <p className="mt-1 text-sm text-foreground/60">
                  It may be outside the current channel or no longer available.
                </p>
                <button
                  className="mt-4 rounded border px-3 py-2 text-sm hover:bg-panel-muted"
                  onClick={() => navigate(`/notifications/${route.channel}`)}
                  type="button"
                >
                  Back to messages
                </button>
              </div>
            </div>
          ) : (
            <div className="grid min-h-0 flex-1 place-items-center p-6 text-center text-sm text-foreground/60">
              Select a notification to read it.
            </div>
          )}
        </section>
      </div>
    </main>
  );
};

const DesktopTerminalApp = () => {
  const tmux = useResource({ id: "tmuxState" });
  const stream = useStream({ id: "tmuxTerminal" });
  const [selectedSessionId, setSelectedSessionId] = useState(() =>
    selectionFromUrl("session"),
  );
  const sessions = tmux.data?.hierarchy.sessions ?? [];
  const session =
    sessions.find(({ id }) => id === selectedSessionId) ?? sessions[0];

  if (!session) {
    return (
      <main className="p-4">
        {tmux.status === "error" ? tmux.error.message : "Loading tmux…"}
      </main>
    );
  }

  return (
    <main className="flex h-dvh min-h-0 bg-background text-foreground">
      <TmuxXterm
        createAddons={createTerminalAddons}
        onClose={() => undefined}
        onSessionChange={(sessionId) => {
          setSelectedSessionId(sessionId);
          writeSelection("session", sessionId);
        }}
        options={{
          fontFamily: '"Hack Nerd Font Mono", ui-monospace, monospace',
          linkHandler: terminalLinkHandler,
          scrollback: 0,
          theme: tokyoNightTheme,
        }}
        sessionId={session.id}
        stream={stream}
      />
    </main>
  );
};

const WorkspaceApp = () => {
  const workspace = useResource({ id: "workspaceState" });
  const createWindow = useOperation({ id: "createWindow" });
  const killPane = useOperation({ id: "killPane" });
  const killSession = useOperation({ id: "killSession" });
  const moveWindow = useOperation({ id: "moveWindow" });
  const reloadConfig = useOperation({ id: "reloadConfig" });
  const selectPane = useOperation({ id: "selectPane" });
  const selectWindow = useOperation({ id: "selectWindow" });
  const splitPane = useOperation({ id: "splitPane" });
  const [diff, setDiff] = useState<DiffMode>();
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [error, setError] = useState("");
  const [paneViews, setPaneViews] = useState<Record<string, PaneView>>({});
  const activeWindowTabRef = useRef<HTMLButtonElement>(null);
  const diffOrientationFullscreenRef = useRef(false);
  const diffOrientationRequestRef = useRef(0);
  const isMobile = useIsMobile();
  const tmux = workspace.status === "success" ? workspace.data.tmux : undefined;
  const selection = useTmuxSelection(
    tmux ??
      tmuxStateSchema.parse({
        backend: { id: "local" },
        connected: false,
        hierarchy: { sessions: [] },
      }),
  );
  const pane = selection.window?.panes.find(
    (candidate) => candidate.id === selection.window?.activePaneId,
  );
  const sourceControl = useSourceControlData({
    activeComparison: diff,
    path: pane?.path,
  });
  const agentId =
    pane && workspace.status === "success"
      ? workspace.data.agentByPaneId[pane.id]?.agentId
      : undefined;
  const paneViewKey = pane && agentId ? `${pane.id}:${agentId}` : undefined;
  const paneView = paneViewKey
    ? (paneViews[paneViewKey] ?? (isMobile ? "conversation" : "terminal"))
    : "terminal";
  const selectPaneView = (view: PaneView) => {
    if (!paneViewKey) {
      return;
    }
    setPaneViews((current) => ({ ...current, [paneViewKey]: view }));
  };
  const openDiff = useCallback(
    (mode: DiffMode) => {
      setDiff(mode);
      if (!isMobile) {
        return;
      }
      const request = diffOrientationRequestRef.current + 1;
      diffOrientationRequestRef.current = request;
      void lockDiffLandscape().then((enteredFullscreen) => {
        if (request !== diffOrientationRequestRef.current) {
          unlockDiffLandscape(enteredFullscreen);
          return;
        }
        diffOrientationFullscreenRef.current = enteredFullscreen;
      });
    },
    [isMobile],
  );
  const closeDiff = useCallback(() => {
    setDiff(undefined);
    diffOrientationRequestRef.current += 1;
    unlockDiffLandscape(diffOrientationFullscreenRef.current);
    diffOrientationFullscreenRef.current = false;
  }, []);
  const run = async (operation: () => Promise<unknown>) => {
    try {
      setError("");
      await operation();
      workspace.refetch();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : String(cause));
    }
  };
  const selectTmuxWindow = async (window: TmuxWindow) => {
    if (!selection.session) {
      return false;
    }
    try {
      setError("");
      await selectWindow.mutateAsync({
        sessionId: selection.session.id,
        windowId: window.id,
      });
      await workspace.refetch();
      return true;
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : String(cause));
      return false;
    }
  };
  const navigatePane = async (direction: "down" | "left" | "right" | "up") => {
    const panes = selection.window?.panes ?? [];
    const index = pane ? panes.indexOf(pane) : -1;
    const offset = direction === "left" || direction === "up" ? -1 : 1;
    const next = panes[(index + offset + panes.length) % panes.length];
    if (next && selection.window) {
      await run(() =>
        selectPane.mutateAsync({
          paneId: next.id,
          windowId: selection.window!.id,
        }),
      );
    }
  };
  const navigateWindow = async (offset: -1 | 1) => {
    const windows = selection.session?.windows ?? [];
    const index = selection.window ? windows.indexOf(selection.window) : -1;
    const next = windows[(index + offset + windows.length) % windows.length];
    return next ? selectTmuxWindow(next) : false;
  };
  const selectWindowByIndex = (index: number) => {
    const window = selection.session?.windows.find(
      (candidate) => candidate.index === index,
    );
    if (window) {
      void selectTmuxWindow(window);
    }
  };
  const createPiWindow = () => {
    if (!pane) {
      return;
    }
    void run(async () => {
      const result = await createWindow.mutateAsync({
        launch: "pi",
        paneId: pane.id,
      });
      if (result.outcome === "error") {
        throw new Error(result.message);
      }
      if (result.outcome === "not-found") {
        throw new Error(`Pane is no longer available: ${pane.id}`);
      }
    });
  };
  const killActivePane = () => {
    if (!pane || !window.confirm("Kill active tmux pane?")) {
      return;
    }
    void run(() => killPane.mutateAsync({ paneId: pane.id }));
  };

  useCommand(
    commands.createWindow,
    pane
      ? {
          params: { paneId: pane.id },
          run: () =>
            run(async () => {
              const result = await createWindow.mutateAsync({
                paneId: pane.id,
              });
              if (result.outcome === "error") {
                throw new Error(result.message);
              }
              if (result.outcome === "not-found") {
                throw new Error(`Pane is no longer available: ${pane.id}`);
              }
            }),
        }
      : skipToken,
  );
  useCommand(
    commands.killPane,
    pane
      ? {
          params: { paneId: pane.id },
          run: () => run(() => killPane.mutateAsync({ paneId: pane.id })),
        }
      : skipToken,
  );
  useCommand(
    commands.killSession,
    selection.session
      ? {
          params: { sessionId: selection.session.id },
          run: () =>
            run(() =>
              killSession.mutateAsync({ sessionId: selection.session!.id }),
            ),
        }
      : skipToken,
  );
  useCommand(
    commands.moveWindowLeft,
    selection.window
      ? {
          params: { windowId: selection.window.id },
          run: () =>
            run(() =>
              moveWindow.mutateAsync({
                direction: "left",
                windowId: selection.window!.id,
              }),
            ),
        }
      : skipToken,
  );
  useCommand(
    commands.moveWindowRight,
    selection.window
      ? {
          params: { windowId: selection.window.id },
          run: () =>
            run(() =>
              moveWindow.mutateAsync({
                direction: "right",
                windowId: selection.window!.id,
              }),
            ),
        }
      : skipToken,
  );
  useCommand(commands.openBaseDiff, {
    enabled: Boolean(pane),
    run: () => openDiff("base"),
  });
  useCommand(commands.openCommandPalette, {
    run: () => setPaletteOpen(true),
  });
  useCommand(commands.openUncommittedDiff, {
    enabled: Boolean(pane),
    run: () => openDiff("uncommitted"),
  });
  useCommand(commands.openSessionPicker, {
    run: () => setPickerOpen(true),
  });
  useCommand(commands.previousWindow, {
    enabled: Boolean(selection.window),
    run: () => navigateWindow(-1),
  });
  useCommand(commands.nextWindow, {
    enabled: Boolean(selection.window),
    run: () => navigateWindow(1),
  });
  useCommand(commands.selectWindow1, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(1),
  });
  useCommand(commands.selectWindow2, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(2),
  });
  useCommand(commands.selectWindow3, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(3),
  });
  useCommand(commands.selectWindow4, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(4),
  });
  useCommand(commands.selectWindow5, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(5),
  });
  useCommand(commands.selectWindow6, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(6),
  });
  useCommand(commands.selectWindow7, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(7),
  });
  useCommand(commands.selectWindow8, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(8),
  });
  useCommand(commands.selectWindow9, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(9),
  });
  useCommand(commands.selectWindow10, {
    enabled: Boolean(selection.session),
    run: () => selectWindowByIndex(10),
  });
  useCommand(commands.paneDown, {
    enabled: Boolean(pane),
    run: () => navigatePane("down"),
  });
  useCommand(commands.paneLeft, {
    enabled: Boolean(pane),
    run: () => navigatePane("left"),
  });
  useCommand(commands.paneRight, {
    enabled: Boolean(pane),
    run: () => navigatePane("right"),
  });
  useCommand(commands.paneUp, {
    enabled: Boolean(pane),
    run: () => navigatePane("up"),
  });
  useCommand(commands.reloadConfig, {
    run: () => run(() => reloadConfig.mutateAsync()),
  });
  useCommand(
    commands.splitHorizontal,
    pane
      ? {
          params: { paneId: pane.id },
          run: () =>
            run(() =>
              splitPane.mutateAsync({
                direction: "horizontal",
                paneId: pane.id,
              }),
            ),
        }
      : skipToken,
  );
  useCommand(
    commands.splitVertical,
    pane
      ? {
          params: { paneId: pane.id },
          run: () =>
            run(() =>
              splitPane.mutateAsync({ direction: "vertical", paneId: pane.id }),
            ),
        }
      : skipToken,
  );

  useEffect(() => closeDiff(), [closeDiff, pane?.id, pane?.path]);
  useEffect(() => {
    activeWindowTabRef.current?.scrollIntoView({
      block: "nearest",
      inline: "nearest",
    });
  }, [selection.window?.id]);
  const sessionsById = useMemo(
    () =>
      new Map(
        tmux?.hierarchy.sessions.map((session) => [session.id, session]) ?? [],
      ),
    [tmux],
  );

  if (workspace.status !== "success") {
    return (
      <main className="p-4">
        {workspace.status === "error"
          ? workspace.error.message
          : "Loading workspace…"}
      </main>
    );
  }

  return (
    <SidebarProvider
      data-om-background-notifications-slotted=""
      defaultOpen={false}
      inert={sourceControl.active && pane ? true : undefined}
    >
      <TmuxSidebar
        connected={Boolean(tmux?.connected)}
        diffEnabled={Boolean(pane)}
        onOpenBaseDiff={() => openDiff("base")}
        onOpenUncommittedDiff={() => openDiff("uncommitted")}
        onOpenNotifications={openNotifications}
        onOpenSettings={() => navigate("/settings")}
        onSelectSession={(sessionId) => {
          const session = sessionsById.get(sessionId);
          if (session) {
            selection.selectSession(session);
          }
        }}
        selectedSessionId={selection.session?.id}
        sessions={tmux?.hierarchy.sessions ?? []}
      />
      <SidebarInset className="bg-background text-foreground">
        <main className="relative min-h-0 flex-1">
          {pane ? (
            <div className="flex h-full min-h-0 flex-col">
              {isMobile ? (
                <MobileWindowSwiper
                  enabled={(selection.session?.windows.length ?? 0) > 1}
                  onNavigate={navigateWindow}
                >
                  <PaneViewport
                    agentId={agentId}
                    onClose={() =>
                      run(() => killPane.mutateAsync({ paneId: pane.id }))
                    }
                    onError={setError}
                    onSessionChange={selection.selectSessionId}
                    paneView={paneView}
                    selectPaneView={selectPaneView}
                    sessionId={selection.session!.id}
                  />
                </MobileWindowSwiper>
              ) : (
                <PaneViewport
                  agentId={agentId}
                  onClose={() =>
                    run(() => killPane.mutateAsync({ paneId: pane.id }))
                  }
                  onError={setError}
                  onSessionChange={selection.selectSessionId}
                  paneView={paneView}
                  selectPaneView={selectPaneView}
                  sessionId={selection.session!.id}
                />
              )}
            </div>
          ) : (
            <div className="grid h-full place-items-center">
              No tmux pane selected
            </div>
          )}
        </main>
        <footer className="order-first flex shrink-0 flex-col border-b md:hidden">
          <div className="order-last flex min-w-0 md:order-first md:flex-1">
            <div className="min-w-0 flex-1 overflow-x-auto pl-2">
              <Tabs
                onValueChange={(windowId) => {
                  const window = selection.session?.windows.find(
                    (candidate) => candidate.id === windowId,
                  );
                  if (window) {
                    void selectTmuxWindow(window);
                  }
                }}
                value={selection.window?.id}
              >
                <TabsList className="flex-nowrap">
                  {selection.session?.windows.map((window) => (
                    <TabsTrigger
                      className="shrink-0 whitespace-nowrap"
                      key={window.id}
                      onClick={focusTerminal}
                      ref={
                        window.id === selection.window?.id
                          ? activeWindowTabRef
                          : undefined
                      }
                      value={window.id}
                    >
                      {tmuxWindowLabel(window)}
                    </TabsTrigger>
                  ))}
                </TabsList>
              </Tabs>
            </div>
            <button
              aria-label="Create tmux window and launch Pi"
              className="flex w-9 shrink-0 items-center justify-center border-l px-1 text-xl"
              disabled={!pane}
              onClick={createPiWindow}
              type="button"
            >
              +
            </button>
            <button
              aria-label="Kill active tmux pane"
              className="flex w-9 shrink-0 items-center justify-center border-l px-1 text-xl text-red-300"
              disabled={!pane}
              onClick={killActivePane}
              type="button"
            >
              ×
            </button>
          </div>
          <div className="order-first flex min-w-0 items-center gap-2 border-b px-3 py-1 text-sm md:order-last md:ml-auto md:shrink-0 md:border-b-0 md:py-0">
            <button
              aria-label="Open tmux session picker"
              className="flex min-w-0 items-center gap-1 font-semibold"
              onClick={() => setPickerOpen(true)}
              type="button"
            >
              <span className="truncate">
                {selection.session?.name ?? "No session"}
              </span>
              <span aria-hidden="true" className="shrink-0 text-xs">
                ▾
              </span>
            </button>
            <span className="hidden min-w-0 items-center gap-2 min-[30rem]:flex">
              <span aria-hidden="true" className="text-foreground/40">
                ·
              </span>
              <span className="truncate text-foreground/60">
                {workspace.data.hostname}
              </span>
            </span>
            <span aria-hidden="true" className="mr-auto" />
            {agentId ? (
              <PaneViewToggle
                compact
                onSelect={selectPaneView}
                value={paneView}
              />
            ) : null}
            <SidebarTrigger
              aria-label="Open or close workspace menu"
              className="shrink-0 md:hidden"
            />
          </div>
        </footer>
        {error ? (
          <p className="bg-red-950 p-2 text-red-200" role="alert">
            {error}
          </p>
        ) : null}
        {pickerOpen ? (
          <SessionPicker
            close={() => setPickerOpen(false)}
            selectSessionId={(sessionId) => {
              const session = sessionsById.get(sessionId);
              if (session) {
                selection.selectSession(session);
              }
            }}
          />
        ) : null}
        {paletteOpen ? (
          <CommandPalette close={() => setPaletteOpen(false)} />
        ) : null}
      </SidebarInset>
      {sourceControl.active && pane ? (
        <SourceControlPortal close={closeDiff} data={sourceControl.active} />
      ) : null}
    </SidebarProvider>
  );
};

const App = () => {
  const isMobile = useIsMobile();
  const path = useRoutePath();
  const route = notificationRoute(path);
  useCommand(commands.openNotifications, {
    run: openNotifications,
  });
  useEffect(() => {
    if (
      path === "/notifications" ||
      (path.startsWith("/notifications/") && !route)
    ) {
      navigate("/notifications/all", true);
    }
  }, [path, route]);
  if (!isMobile) {
    return <DesktopTerminalApp />;
  }
  if (route) {
    return <NotificationsApp route={route} />;
  }
  if (path === "/settings") {
    return <SettingsApp />;
  }
  return <WorkspaceApp />;
};

export default defineOvermuxClient({
  chordPrefixes: [
    { binding: "F12", unmatched: "replay-to-focused-input" },
    { binding: "§", unmatched: "replay-to-focused-input" },
  ],
  commands,
  component: App,
});
