import { createRoot } from "react-dom/client";
import {
  act,
  createElement,
  forwardRef,
  StrictMode,
  useEffect,
  useImperativeHandle,
  useState,
  type Dispatch,
  type SetStateAction,
} from "react";
import {
  createMemoryHistory,
  createRootRoute,
  createRoute,
  createRouter,
  RouterProvider,
} from "@tanstack/react-router";
import { afterEach, expect, test as testCases, vi } from "vitest";
import type {
  TmuxTerminalConnection,
  TmuxTerminalLocation,
  UseTmuxTerminalResult,
} from "@overmux/tmux/react";

import { RootTmuxRedirectRoute } from "../components/routes/root-tmux-redirect-route";
import {
  notificationSearchSchema,
  NotificationsRedirectRoute,
} from "../notifications";
import { TmuxTerminalLayoutRoute } from "../components/routes/tmux-terminal-layout-route";
import { tmuxPathFromLocation, tmuxTargetFromParams } from "./tmux-routing";
import { createOvermuxHistory } from "./router-history";

let terminal: UseTmuxTerminalResult;
let xtermMounts = 0;
let stream: TmuxTerminalConnection;
let setStream: Dispatch<SetStateAction<TmuxTerminalConnection>>;
let setTerminalError: Dispatch<SetStateAction<Error | undefined>>;
let setTerminalLocation: Dispatch<
  SetStateAction<TmuxTerminalLocation | undefined>
>;
let createPiTmuxWindow: ReturnType<typeof vi.fn>;
let killTmuxPane: ReturnType<typeof vi.fn>;
let terminalFocuses = 0;

(globalThis as { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT =
  true;

vi.mock("@overmux/tmux/react", () => ({
  TmuxXterm: forwardRef((_props, ref) => {
    useEffect(() => {
      xtermMounts += 1;
    }, []);
    useImperativeHandle(ref, () => ({
      focus: () => {
        terminalFocuses += 1;
      },
    }));
    return null;
  }),
  useTmuxTerminal: () => {
    const [location, setLocation] = useState<TmuxTerminalLocation>();
    const [error, setError] = useState<Error>();
    setTerminalLocation = setLocation;
    setTerminalError = setError;
    return { ...terminal, location, error };
  },
}));
vi.mock("./overmux-hooks", () => ({
  useResource: () => ({
    status: "success",
    data: {
      hierarchy: {
        sessions: [
          {
            activeWindowId: "@2",
            id: "$1",
            name: "test",
            windows: [
              {
                activePaneId: "%647",
                id: "@2",
                name: "zsh",
                panes: [{ id: "%647", path: "/work/project" }],
              },
              {
                activePaneId: "%999",
                id: "@3",
                name: "editor",
                panes: [{ id: "%999", path: "/work/other" }],
              },
            ],
          },
        ],
      },
    },
  }),
  useOperation: ({ id }: { id: string }) => ({
    mutateAsync: id === "createPiTmuxWindow" ? createPiTmuxWindow : killTmuxPane,
  }),
  useStream: () => {
    const [value, setValue] = useState(stream);
    setStream = setValue;
    return { ...value };
  },
}));

let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
let activeHistory: ReturnType<typeof createMemoryHistory> | undefined;

afterEach(async () => {
  await act(async () => root?.unmount());
  container?.remove();
  activeHistory?.destroy();
  window.history.replaceState({}, "", "/");
});

const location = { sessionId: "$1", windowId: "@2", paneId: "%647" };
const nextLocation = { sessionId: "$1", windowId: "@3", paneId: "%999" };
const buttonNamed = (name: string) =>
  [...container.querySelectorAll<HTMLButtonElement>("button")].find(
    (button) => button.textContent === name,
  );
const setup = async (
  path: string,
  goTo = vi.fn().mockResolvedValue(location),
  history = createMemoryHistory({ initialEntries: [path] }),
) => {
  activeHistory = history;
  stream = {
    connectionId: undefined,
    close: vi.fn(),
    send: vi.fn(),
    status: "opening",
    subscribe: vi.fn(),
  };
  terminal = {
    attachRenderer: vi.fn(),
    error: undefined,
    goTo,
    input: vi.fn(),
    location: undefined,
    resize: vi.fn(),
  };
  xtermMounts = 0;
  terminalFocuses = 0;
  createPiTmuxWindow = vi.fn().mockResolvedValue(undefined);
  killTmuxPane = vi.fn().mockResolvedValue(undefined);
  const rootRoute = createRootRoute();
  const notificationsRoute = createRoute({
    getParentRoute: () => rootRoute,
    path: "notifications",
  });
  const notificationsIndexRoute = createRoute({
    getParentRoute: () => notificationsRoute,
    path: "/",
    component: NotificationsRedirectRoute,
  });
  const notificationChannelRoute = createRoute({
    getParentRoute: () => notificationsRoute,
    path: "$channel",
    component: NotificationsRedirectRoute,
  });
  const notificationDetailRoute = createRoute({
    getParentRoute: () => notificationChannelRoute,
    path: "$id",
  });
  const tmuxRoute = createRoute({
    getParentRoute: () => rootRoute,
    path: "tmux",
    validateSearch: notificationSearchSchema,
    component: TmuxTerminalLayoutRoute,
  });
  const tmuxIndexRoute = createRoute({
    getParentRoute: () => tmuxRoute,
    path: "/",
    component: RootTmuxRedirectRoute,
  });
  const sessionRoute = createRoute({
    getParentRoute: () => tmuxRoute,
    path: "$sessionId",
  });
  const windowRoute = createRoute({
    getParentRoute: () => tmuxRoute,
    path: "$sessionId/$windowId",
  });
  const paneRoute = createRoute({
    getParentRoute: () => tmuxRoute,
    path: "$sessionId/$windowId/$paneId",
  });
  const router = createRouter({
    routeTree: rootRoute.addChildren([
      notificationsRoute.addChildren([
        notificationsIndexRoute,
        notificationChannelRoute.addChildren([notificationDetailRoute]),
      ]),
      tmuxRoute.addChildren([
        tmuxIndexRoute,
        sessionRoute,
        windowRoute,
        paneRoute,
      ]),
    ]),
    history,
  });
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
  await act(async () => {
    root.render(
      createElement(
        StrictMode,
        null,
        createElement(RouterProvider, { router }),
      ),
    );
  });
  return { goTo, router };
};

const targetCases = [
  { name: "session", path: "/tmux/1", target: { sessionId: "$1" } },
  {
    name: "window",
    path: "/tmux/1/2",
    target: { sessionId: "$1", windowId: "@2" },
  },
  {
    name: "pane",
    path: "/tmux/1/2/647",
    target: location,
  },
];
testCases.each(targetCases)(
  "requests partial and numeric $name targets without waiting for the stream",
  async ({ path, target }) => {
    const app = await setup(path);
    expect(app.goTo).toHaveBeenCalledExactlyOnceWith(target);
  },
);

testCases(
  "keeps a direct notification masked while selecting the default tmux session",
  async () => {
    const app = await setup("/notifications/agent");
    await act(async () => {});

    expect(app.router.history.location.pathname).toBe("/notifications/agent");
    expect(app.router.stores.location.get().pathname).toBe("/tmux/1");
    const dialog = document.querySelector<HTMLElement>("[role='dialog']");
    expect(dialog).toBeTruthy();
    expect(app.goTo).toHaveBeenCalledExactlyOnceWith({ sessionId: "$1" });
    expect(xtermMounts).toBe(2);

    await act(async () => {
      dialog?.dispatchEvent(
        new KeyboardEvent("keydown", {
          bubbles: true,
          cancelable: true,
          key: "Escape",
        }),
      );
    });
    expect(app.router.history.location.pathname).toBe("/tmux/1");
    expect(xtermMounts).toBe(2);
  },
);

testCases(
  "uses the first target made available after /tmux redirects",
  async () => {
    const app = await setup("/tmux");
    expect(app.router.history.location.pathname).toBe("/tmux/1");
    expect(app.goTo).toHaveBeenCalledExactlyOnceWith({ sessionId: "$1" });
  },
);

testCases(
  "replaces the address for terminal locations without requesting an echo",
  async () => {
    const app = await setup("/tmux/1");
    await act(async () => {
      setTerminalLocation(location);
    });
    expect(app.router.history.location.pathname).toBe(
      tmuxPathFromLocation(location),
    );
    expect(app.router.history.length).toBe(1);

    await act(async () => {
      setTerminalLocation(nextLocation);
    });
    expect(app.router.history.location.pathname).toBe(
      tmuxPathFromLocation(nextLocation),
    );
    expect(app.router.history.length).toBe(1);
    expect(app.goTo).toHaveBeenCalledExactlyOnceWith({ sessionId: "$1" });
  },
);

testCases(
  "routes desktop pushState alone to another pane and back without remounting xterm",
  async () => {
    window.history.replaceState({}, "", tmuxPathFromLocation(location));
    const app = await setup("/", undefined, createOvermuxHistory());
    await act(async () => setTerminalLocation(location));
    const mounts = xtermMounts;

    for (const target of [nextLocation, location]) {
      const request = Promise.withResolvers<TmuxTerminalLocation>();
      app.goTo.mockReturnValueOnce(request.promise);
      await act(async () => {
        window.history.pushState(
          window.history.state,
          "",
          tmuxPathFromLocation(target),
        );
      });

      expect(app.goTo).toHaveBeenLastCalledWith(target);
      // The previous confirmed pane must not overwrite a pending deep link.
      expect(app.router.history.location.pathname).toBe(
        tmuxPathFromLocation(target),
      );
      await act(async () => {
        setTerminalLocation(target);
        request.resolve(target);
      });
      expect(app.router.history.location.pathname).toBe(
        tmuxPathFromLocation(target),
      );
      expect(xtermMounts).toBe(mounts);
    }
    expect(app.goTo).toHaveBeenCalledTimes(3);
  },
);

testCases("ignores a superseded URL request's failure", async () => {
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  const stale = Promise.withResolvers<TmuxTerminalLocation>();
  app.goTo.mockReturnValueOnce(stale.promise);
  await act(async () =>
    app.router.history.push(tmuxPathFromLocation(nextLocation)),
  );
  expect(app.goTo).toHaveBeenLastCalledWith(nextLocation);

  await act(async () =>
    app.router.history.push(tmuxPathFromLocation(location)),
  );
  await act(async () => stale.reject(new Error("Old request failed")));

  expect(app.goTo).toHaveBeenLastCalledWith(location);
  expect(app.router.history.location.pathname).toBe(
    tmuxPathFromLocation(location),
  );
  expect(container.textContent).not.toContain("Old request failed");
});

testCases.each(["reconnect", "batched reconnect"])(
  "leaves unchanged-URL recovery to the terminal hook after %s",
  async (scenario) => {
    const app = await setup(tmuxPathFromLocation(location));
    await act(async () => setTerminalLocation(location));
    const mounts = xtermMounts;
    if (scenario === "reconnect") {
      await act(async () => {
        setStream({ ...stream, connectionId: undefined, status: "closed" });
        setTerminalLocation(undefined);
      });
      expect(app.goTo).toHaveBeenCalledTimes(1);
    }
    await act(async () => {
      setStream({ ...stream, connectionId: Symbol(), status: "open" });
      setTerminalLocation(undefined);
    });
    expect(app.goTo).toHaveBeenCalledTimes(1);
    expect(app.goTo).toHaveBeenLastCalledWith(location);
    await act(async () => setTerminalLocation(nextLocation));
    expect(app.router.history.location.pathname).toBe(
      tmuxPathFromLocation(nextLocation),
    );
    expect(app.router.history.length).toBe(1);
    expect(app.goTo).toHaveBeenCalledTimes(1);
    expect(xtermMounts).toBe(mounts);
  },
);

testCases(
  "protects a pending explicit URL from native observations",
  async () => {
    const current = Promise.withResolvers<TmuxTerminalLocation>();
    const app = await setup(
      "/tmux/1",
      vi.fn().mockReturnValue(current.promise),
    );
    await act(async () =>
      setStream({ ...stream, connectionId: Symbol(), status: "open" }),
    );
    // A native observation cannot replace the external URL while goTo is pending.
    await act(async () => setTerminalLocation(nextLocation));
    expect(app.router.history.location.pathname).toBe("/tmux/1");
    await act(async () => current.resolve(nextLocation));
    expect(app.router.history.location.pathname).toBe(
      tmuxPathFromLocation(nextLocation),
    );
    expect(app.goTo).toHaveBeenCalledTimes(1);
  },
);

testCases("returns a failed URL request to the confirmed location without a banner", async () => {
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  app.goTo.mockRejectedValueOnce(new Error("No session $9"));

  await act(async () => app.router.history.push("/tmux/9"));

  expect(app.router.history.location.pathname).toBe(
    tmuxPathFromLocation(location),
  );
  expect(container.textContent).not.toContain("No session $9");
});

testCases("later server confirmations replace a failed URL request", async () => {
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  app.goTo.mockRejectedValueOnce(new Error("No session $9"));
  await act(async () => app.router.history.push("/tmux/9"));
  await act(async () => setTerminalLocation(nextLocation));

  expect(app.router.history.location.pathname).toBe(
    tmuxPathFromLocation(nextLocation),
  );
  expect(container.textContent).not.toContain("No session $9");
});

testCases("a late failed request cannot revert a newer confirmed location", async () => {
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  const stale = Promise.withResolvers<TmuxTerminalLocation>();
  const current = Promise.withResolvers<TmuxTerminalLocation>();
  const confirmed = { sessionId: "$2", windowId: "@4", paneId: "%10" };
  app.goTo.mockReturnValueOnce(stale.promise).mockReturnValueOnce(current.promise);

  await act(async () => app.router.history.push(tmuxPathFromLocation(nextLocation)));
  await act(async () => app.router.history.push("/tmux/2"));
  await act(async () => setTerminalLocation(confirmed));
  await act(async () => stale.reject(new Error("No session $1")));
  await act(async () => current.resolve(confirmed));

  expect(app.router.history.location.pathname).toBe(
    tmuxPathFromLocation(confirmed),
  );
  expect(container.textContent).not.toContain("No session $1");
});

testCases("shows hook recovery failures without retrying the URL", async () => {
  const app = await setup("/tmux/1");
  await act(async () =>
    setTerminalError(new Error("Recovery session disappeared")),
  );
  expect(container.textContent).toContain(
    "Could not open tmux location: Recovery session disappeared",
  );
  expect(app.goTo).toHaveBeenCalledTimes(1);
  expect(app.router.history.location.pathname).toBe("/tmux/1");
});

testCases("silently handles a failed initial navigation", async () => {
  const app = await setup(
    "/tmux/1",
    vi.fn().mockRejectedValue(new Error("No session $1")),
  );
  await act(async () => {});
  expect(container.textContent).not.toContain("No session $1");
  expect(app.router.history.location.pathname).toBe("/tmux/1");
});

testCases.each(["$1", "-1", "1.5", "01", "abc"])(
  "rejects invalid URL ID %s without navigating tmux",
  async (id) => {
    const app = await setup(`/tmux/${encodeURIComponent(id)}`);
    await act(async () => setTerminalLocation(location));
    expect(app.router.history.location.pathname).toBe(
      `/tmux/${encodeURIComponent(id)}`,
    );
    expect(app.goTo).not.toHaveBeenCalled();
    expect(container.textContent).toContain(
      "Tmux URL IDs must be nonnegative integers",
    );
  },
);

testCases("formats native IDs as positional numbers", () => {
  expect(tmuxPathFromLocation(location)).toBe("/tmux/1/2/647");
  expect(
    tmuxTargetFromParams({ sessionId: "0", windowId: "0", paneId: "0" }),
  ).toEqual({
    sessionId: "$0",
    windowId: "@0",
    paneId: "%0",
  });
  expect(() =>
    tmuxTargetFromParams({ sessionId: "1", windowId: "@2" }),
  ).toThrow();
  expect(() =>
    tmuxTargetFromParams({ sessionId: "1", windowId: "2", paneId: "%3" }),
  ).toThrow();
});

testCases("does not create targets without a session", () => {
  expect(tmuxTargetFromParams({})).toBeUndefined();
});

testCases("switches windows without requesting terminal focus", async () => {
  const navigation = Promise.withResolvers<TmuxTerminalLocation>();
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  app.goTo.mockReturnValueOnce(navigation.promise);

  await act(async () => buttonNamed("editor")?.click());
  expect(app.goTo).toHaveBeenLastCalledWith({ sessionId: "$1", windowId: "@3" });
  expect(terminalFocuses).toBe(0);
  await act(async () => navigation.resolve(nextLocation));
  expect(terminalFocuses).toBe(0);
});

testCases("leaves focus unchanged when selecting the confirmed active window", async () => {
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  await act(async () => buttonNamed("project")?.click());
  expect(terminalFocuses).toBe(0);
  expect(app.goTo).toHaveBeenCalledExactlyOnceWith(location);
});

testCases("does not focus after a superseded window navigation", async () => {
  const navigation = Promise.withResolvers<TmuxTerminalLocation>();
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  app.goTo.mockReturnValueOnce(navigation.promise);
  await act(async () => buttonNamed("editor")?.click());
  await act(async () => app.router.history.push(tmuxPathFromLocation(location)));
  await act(async () => navigation.resolve(nextLocation));
  expect(terminalFocuses).toBe(0);
});

testCases("keeps focus away when window navigation fails", async () => {
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  app.goTo.mockRejectedValueOnce(new Error("Window disappeared"));

  await act(async () => buttonNamed("editor")?.click());
  await act(async () => {});
  expect(terminalFocuses).toBe(0);
  expect(container.textContent).not.toContain("Window disappeared");
});

testCases("confirms, captures, and reports tmux pane actions", async () => {
  const app = await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  const confirm = vi.fn().mockReturnValueOnce(false);
  Object.assign(window, { confirm });
  await act(async () =>
    container
      .querySelector<HTMLButtonElement>("button[aria-label='Kill active tmux pane']")
      ?.click(),
  );
  expect(killTmuxPane).not.toHaveBeenCalled();

  const killed = Promise.withResolvers<void>();
  killTmuxPane.mockReturnValueOnce(killed.promise);
  confirm.mockReturnValueOnce(true);
  await act(async () =>
    container
      .querySelector<HTMLButtonElement>("button[aria-label='Kill active tmux pane']")
      ?.click(),
  );
  await act(async () => setTerminalLocation(nextLocation));
  expect(killTmuxPane).toHaveBeenCalledExactlyOnceWith({ paneId: "%647" });
  await act(async () => killed.resolve());
  expect(app.goTo).toHaveBeenCalled();
});

testCases("reports failed Pi-window creation without changing the terminal", async () => {
  await setup(tmuxPathFromLocation(location));
  await act(async () => setTerminalLocation(location));
  createPiTmuxWindow.mockRejectedValueOnce(new Error("Tmux unavailable"));
  await act(async () =>
    container
      .querySelector<HTMLButtonElement>("button[aria-label='Create Pi window']")
      ?.click(),
  );
  await act(async () => await new Promise((resolve) => setTimeout(resolve)));
  expect(createPiTmuxWindow).toHaveBeenCalledWith({ paneId: "%647" });
  expect(container.textContent).toContain("Tmux action failed: Tmux unavailable");
});
