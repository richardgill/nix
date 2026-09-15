import {
  Bell,
  GitCompare,
  GitCompareArrows,
  Settings,
  SquareTerminal,
} from "lucide-react";

type TmuxSession = {
  activeWindowId: string;
  id: string;
  name: string;
  windows: Array<{
    activePaneId: string;
    id: string;
    panes: Array<{ id: string; path: string }>;
  }>;
};

const sessionPath = (session: TmuxSession) => {
  const window = session.windows.find(
    ({ id }) => id === session.activeWindowId,
  );
  return window?.panes.find((pane) => pane.id === window.activePaneId)?.path;
};

const sidebarSessions = (sessions: TmuxSession[]) =>
  sessions.filter((session) => !["background", "code"].includes(session.name));

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarTrigger,
  useSidebar,
} from "../shadcn/sidebar";

type TmuxSidebarProps = {
  connected: boolean;
  diffEnabled: boolean;
  onOpenBaseDiff: () => void;
  onOpenUncommittedDiff: () => void;
  onOpenNotifications: () => void;
  onOpenSettings: () => void;
  onSelectSession: (sessionId: string) => void;
  selectedSessionId: string | undefined;
  sessions: TmuxSession[];
};

export const TmuxSidebar = ({
  connected,
  diffEnabled,
  onOpenBaseDiff,
  onOpenUncommittedDiff,
  onOpenNotifications,
  onOpenSettings,
  onSelectSession,
  selectedSessionId,
  sessions,
}: TmuxSidebarProps) => {
  const { isMobile, open, setOpenMobile } = useSidebar();
  if (isMobile) {
    return (
      <Sidebar>
        <SidebarHeader className="!p-0 gap-1">
          <SidebarMenu className="min-w-0 flex-1">
            <SidebarMenuItem>
              <SidebarMenuButton
                className="!border-l-0 !px-2 gap-1 disabled:cursor-not-allowed disabled:opacity-50"
                disabled={!diffEnabled}
                onClick={() => {
                  setOpenMobile(false);
                  onOpenUncommittedDiff();
                }}
              >
                <GitCompare aria-hidden="true" className="size-5 shrink-0" />
                <span className="truncate">Diff</span>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
          <button
            aria-label="Open settings"
            className="flex size-10 shrink-0 items-center justify-center rounded hover:bg-panel-muted"
            onClick={() => {
              setOpenMobile(false);
              onOpenSettings();
            }}
            type="button"
          >
            <Settings aria-hidden="true" className="size-5" />
          </button>
        </SidebarHeader>
        <SidebarContent className="!p-0 flex min-h-0 flex-col overflow-hidden">
          <SidebarMenu className="shrink-0 pb-1">
            <SidebarMenuItem>
              <SidebarMenuButton
                className="!border-l-0 !px-2 gap-1 disabled:cursor-not-allowed disabled:opacity-50"
                disabled={!diffEnabled}
                onClick={() => {
                  setOpenMobile(false);
                  onOpenBaseDiff();
                }}
              >
                <GitCompareArrows
                  aria-hidden="true"
                  className="size-5 shrink-0"
                />
                <span className="truncate">Base diff</span>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton
                className="!border-l-0 !px-2 gap-1"
                onClick={() => {
                  setOpenMobile(false);
                  onOpenNotifications();
                }}
              >
                <Bell aria-hidden="true" className="size-5 shrink-0" />
                <span className="truncate">Notifications</span>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
          <SidebarMenu
            aria-label="Tmux sessions"
            className="min-h-0 flex-1 content-start overflow-y-auto border-t"
          >
            {sidebarSessions(sessions).map((session) => (
              <SidebarMenuItem key={session.id}>
                <SidebarMenuButton
                  className="!border-l-0 !px-2 gap-1"
                  isActive={session.id === selectedSessionId}
                  onClick={() => {
                    onSelectSession(session.id);
                    setOpenMobile(false);
                  }}
                  title={sessionPath(session)}
                >
                  <SquareTerminal
                    aria-hidden="true"
                    className="size-5 shrink-0"
                  />
                  <span className="truncate">{session.name}</span>
                </SidebarMenuButton>
              </SidebarMenuItem>
            ))}
          </SidebarMenu>
        </SidebarContent>
      </Sidebar>
    );
  }
  const collapsed = !open;
  return (
    <Sidebar>
      <SidebarHeader className={collapsed ? "justify-center p-1" : undefined}>
        {collapsed ? null : <h1 className="font-semibold">Tmux</h1>}
        <SidebarTrigger
          aria-label={
            collapsed
              ? "Expand tmux sessions sidebar"
              : "Collapse tmux sessions sidebar"
          }
        >
          {collapsed ? "»" : "«"}
        </SidebarTrigger>
      </SidebarHeader>
      {collapsed ? null : (
        <>
          <SidebarContent>
            <SidebarMenu>
              {sidebarSessions(sessions).map((session) => (
                <SidebarMenuItem key={session.id}>
                  <SidebarMenuButton
                    isActive={session.id === selectedSessionId}
                    onClick={() => {
                      onSelectSession(session.id);
                      if (isMobile) setOpenMobile(false);
                    }}
                    title={sessionPath(session)}
                  >
                    {session.name}
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarContent>
          <SidebarFooter className="flex items-center gap-2">
            <span
              aria-hidden="true"
              className={
                connected
                  ? "size-2 rounded-full bg-green-400"
                  : "size-2 rounded-full bg-red-400"
              }
            />
            {connected ? "connected" : "offline"}
          </SidebarFooter>
        </>
      )}
    </Sidebar>
  );
};
