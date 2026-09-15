import { TmuxXterm, useTmuxTerminal } from "@overmux/tmux/react";
import { createWriteOnlyOsc52ClipboardAddon } from "@overmux/xterm/client";
import { createOvermuxSettingsPath } from "overmux";
import { Menu } from "lucide-react";
import {
  Outlet,
  useRouter,
  useRouterState,
  useSearch,
} from "@tanstack/react-router";
import { useEffect, useRef, useState } from "react";

import { useOperation, useResource, useStream } from "../../utils/overmux-hooks";
import { useTerminalPinchZoom } from "../../utils/use-terminal-pinch-zoom";
import {
  tmuxParamsFromTarget,
  tmuxPathFromLocation,
  tmuxTargetFromPath,
} from "../../utils/tmux-routing";
import {
  notificationFromSearch,
  NotificationsRoute,
  openNotifications,
} from "../../notifications";
import { xtermTheme } from "../../css/xterm-theme";
import { MobileTmuxWindowBar, tmuxWindowLabel } from "../mobile-tmux-window-bar";
import { MobileTmuxWindowSwipe } from "../mobile-tmux-window-swipe";
import { MobileWorkspaceSidebar } from "../mobile-workspace-sidebar";

const asError = (cause: unknown) =>
  cause instanceof Error ? cause : new Error(String(cause));

export const TmuxTerminalLayoutRoute = () => {
  const tmux = useResource({ id: "tmuxState" });
  const createPiTmuxWindow = useOperation({ id: "createPiTmuxWindow" });
  const killTmuxPane = useOperation({ id: "killTmuxPane" });
  const stream = useStream({ id: "tmuxTerminal" });
  const terminal = useTmuxTerminal({ stream });
  const router = useRouter();
  const search = useSearch({ strict: false });
  const location = useRouterState({ select: (state) => state.location });
  const terminalRef = useRef<{ focus: () => void }>(null);
  const {
    containerRef: terminalContainerRef,
    fontSize,
    resetFontSize,
  } = useTerminalPinchZoom();
  const workspaceMenuButtonRef = useRef<HTMLButtonElement>(null);
  const notification = notificationFromSearch(search);
  const requestedPath = useRef<string>(undefined);
  const pendingNavigation = useRef<symbol>(undefined);
  const [navigationPending, setNavigationPending] = useState(false);
  const [actionError, setActionError] = useState<Error>();
  const [workspaceMenuOpen, setWorkspaceMenuOpen] = useState(false);

  // Request the first available URL target once, including after the /tmux redirect.
  // Later URL replacements must not send navigation commands back to tmux.
  // External URL changes also request a target; our own confirmed-location replacements
  // mark requestedPath before navigating so they never echo a command back to tmux.
  const openUrlInTmux = () => {
    // Disconnection rejects goTo; the hook reattaches only its last confirmed session.
    // The route only sends a request when an external URL selects a new target.
    if (
      requestedPath.current === location.pathname ||
      location.pathname === "/tmux"
    ) {
      return;
    }
    requestedPath.current = location.pathname;
    const request = Symbol();
    pendingNavigation.current = request;
    try {
      const target = tmuxTargetFromPath(location.pathname);
      if (!target) {
        pendingNavigation.current = undefined;
        setNavigationPending(false);
        return;
      }
      setNavigationPending(true);
      void terminal.goTo(target).catch(() => {}).finally(() => {
        if (pendingNavigation.current === request) {
          pendingNavigation.current = undefined;
          setNavigationPending(false);
        }
      });
    } catch {
      pendingNavigation.current = undefined;
      setNavigationPending(false);
    }
  };
  useEffect(openUrlInTmux, [location.pathname, terminal.goTo]);

  // Reflect the server-confirmed location in the address, without navigating tmux.
  // Replace the current history entry rather than recording each pane change.
  const syncTmuxLocationUrl = () => {
    if (
      notification ||
      // The server-confirmed location replaces an external URL after its request settles.
      pendingNavigation.current ||
      !terminal.location ||
      location.pathname === tmuxPathFromLocation(terminal.location)
    ) {
      return;
    }
    // A server-confirmed native pane change replaces the URL, but never echoes goTo.
    requestedPath.current = tmuxPathFromLocation(terminal.location);
    void router
      .navigate({
        to: "/tmux/$sessionId/$windowId/$paneId",
        params: tmuxParamsFromTarget(terminal.location),
        search: {},
        replace: true,
      })
      .catch(() => {});
  };
  useEffect(syncTmuxLocationUrl, [
    location.pathname,
    navigationPending,
    notification,
    router,
    terminal.location,
  ]);

  const error =
    terminal.error ?? (tmux.status === "error" ? tmux.error : undefined);
  const selectedSession = tmux.data?.hierarchy.sessions.find(
    (session) => session.id === terminal.location?.sessionId,
  );
  const activeWindow = selectedSession?.windows.find(
    (window) => window.id === terminal.location?.windowId,
  );
  const activePane = activeWindow?.panes.find(
    (pane) => pane.id === terminal.location?.paneId,
  );
  const tabs = (selectedSession?.windows ?? []).map((window) => ({
    id: window.id,
    label: tmuxWindowLabel({
      activePaneDirectory:
        window.panes.find((pane) => pane.id === window.activePaneId)?.path ??
        null,
      windowName: window.name,
    }),
  }));
  const message = !terminal.location
    ? tmux.status === "success" && tmux.data.hierarchy.sessions.length === 0
      ? "No tmux sessions."
      : "Opening tmux location…"
    : undefined;

  const selectSession = (sessionId: string) => {
    void router
      .navigate({
        params: tmuxParamsFromTarget({ sessionId }),
        search: {},
        to: "/tmux/$sessionId",
      })
      .catch(() => {});
  };

  const selectWindow = (windowId: string) => {
    if (!selectedSession || windowId === terminal.location?.windowId) return;
    void router
      .navigate({
        params: tmuxParamsFromTarget({
          sessionId: selectedSession.id,
          windowId,
        }),
        search: {},
        to: "/tmux/$sessionId/$windowId",
      })
      .catch(() => {});
  };

  const createPiWindow = () => {
    const paneId = activePane?.id;
    if (!paneId) return;
    setActionError(undefined);
    void createPiTmuxWindow.mutateAsync({ paneId }).catch((cause: unknown) => {
      setActionError(asError(cause));
    });
  };

  const killActivePane = () => {
    const paneId = activePane?.id;
    if (!paneId || !window.confirm("Kill active tmux pane?")) return;
    setActionError(undefined);
    void killTmuxPane.mutateAsync({ paneId }).catch((cause: unknown) => {
      setActionError(asError(cause));
    });
  };

  const openSettings = () => {
    const returnTo = `${window.location.pathname}${window.location.search}${window.location.hash}`;
    window.location.assign(createOvermuxSettingsPath(returnTo));
  };

  return (
    <main
      // Anchor overlays and stack children in a viewport-height column; zero minimums let xterm shrink when Android's keyboard resizes the viewport.
      className="relative flex h-dvh min-h-0 min-w-0 flex-col bg-background text-foreground"
    >
      <MobileTmuxWindowBar
        actionsDisabled={!activePane}
        activeWindowId={terminal.location?.windowId ?? null}
        onCreatePiWindow={createPiWindow}
        onKillActivePane={killActivePane}
        onSelectWindow={selectWindow}
        tabs={tabs}
      />
      <div className="flex min-h-0 min-w-0 flex-1" ref={terminalContainerRef}>
        <MobileTmuxWindowSwipe
          activeWindowId={terminal.location?.windowId ?? null}
          onSelectWindow={selectWindow}
          windowIds={tabs.map((tab) => tab.id)}
        >
          <TmuxXterm
            className="om-tmux-crop-status-mobile min-w-0"
            ref={terminalRef}
            createAddons={() => [createWriteOnlyOsc52ClipboardAddon()]}
            options={{
              fontFamily: '"Hack Nerd Font Mono", ui-monospace, monospace',
              fontSize,
              theme: xtermTheme,
            }}
            terminal={terminal}
          />
        </MobileTmuxWindowSwipe>
      </div>
      <button
        aria-label="Open workspace menu"
        className="absolute right-3 bottom-3 z-10 rounded-md border bg-background/90 p-2 shadow-sm backdrop-blur-sm md:hidden focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
        onClick={() => setWorkspaceMenuOpen(true)}
        ref={workspaceMenuButtonRef}
        type="button"
      >
        <Menu aria-hidden="true" size={20} />
      </button>
      <MobileWorkspaceSidebar
        onNotifications={() => void openNotifications(router)}
        onOpenChange={setWorkspaceMenuOpen}
        openerRef={workspaceMenuButtonRef}
        onSelectSession={selectSession}
        onSettings={openSettings}
        open={workspaceMenuOpen}
        selectedSessionId={
          tmuxTargetFromPath(location.pathname)?.sessionId ??
          terminal.location?.sessionId ??
          null
        }
        sessions={tmux.data?.hierarchy.sessions ?? []}
      />
      <Outlet />
      <NotificationsRoute
        onCloseAutoFocus={() => terminalRef.current?.focus()}
      />
      {message && !error ? (
        <div className="shrink-0 p-2" role="status">
          {message}
        </div>
      ) : null}
      {actionError ? (
        <div
          className="max-h-32 shrink-0 overflow-y-auto p-2 wrap-anywhere text-[var(--om-color-danger)]"
          role="alert"
        >
          Tmux action failed: {actionError.message}
        </div>
      ) : null}
      {error ? (
        <div
          className="max-h-32 shrink-0 overflow-y-auto p-2 wrap-anywhere text-[var(--om-color-danger)]"
          role="alert"
        >
          Could not open tmux location: {error.message}
          <a className="mt-2 block underline" href="/tmux">
            Go back to /tmux
          </a>
        </div>
      ) : null}
    </main>
  );
};
