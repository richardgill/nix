import type {
  TmuxTerminalLocation,
  TmuxTerminalTarget,
} from "@overmux/tmux/react";

export type TmuxRouteParams = {
  paneId?: string;
  sessionId?: string;
  windowId?: string;
};

export const tmuxTargetFromParams = ({
  sessionId,
  windowId,
  paneId,
}: TmuxRouteParams): TmuxTerminalTarget | undefined => {
  if (!sessionId) {
    return undefined;
  }
  const segments = [sessionId, windowId, paneId].filter(
    (segment) => segment !== undefined,
  );
  if (segments.some((segment) => !/^(0|[1-9][0-9]*)$/.test(segment))) {
    throw new Error("Tmux URL IDs must be nonnegative integers");
  }
  if (!windowId) {
    return { sessionId: `$${sessionId}` };
  }
  if (!paneId) {
    return { sessionId: `$${sessionId}`, windowId: `@${windowId}` };
  }
  return {
    sessionId: `$${sessionId}`,
    windowId: `@${windowId}`,
    paneId: `%${paneId}`,
  };
};

// Read a single location snapshot: router location updates can precede matched params.
export const tmuxTargetFromPath = (pathname: string) => {
  const [, route, sessionId, windowId, paneId] = pathname.split("/");
  if (route !== "tmux") {
    return undefined;
  }
  return tmuxTargetFromParams({
    sessionId: sessionId ? decodeURIComponent(sessionId) : undefined,
    windowId: windowId ? decodeURIComponent(windowId) : undefined,
    paneId: paneId ? decodeURIComponent(paneId) : undefined,
  });
};

export const tmuxParamsFromTarget = <T extends TmuxTerminalTarget>(
  target: T,
): T =>
  Object.fromEntries(
    Object.entries(target).map(([key, id]) => [key, id.slice(1)]),
  ) as T;

export const tmuxPathFromLocation = (location: TmuxTerminalLocation) => {
  const { sessionId, windowId, paneId } = tmuxParamsFromTarget(location);
  return `/tmux/${sessionId}/${windowId}/${paneId}`;
};
