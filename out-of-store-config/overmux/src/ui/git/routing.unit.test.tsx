import { act, useEffect } from "react";
import { createRoot } from "react-dom/client";
import {
  createMemoryHistory,
  createRootRoute,
  createRoute,
  createRouter,
  Outlet,
  RouterProvider,
} from "@tanstack/react-router";
import { afterEach, expect, test as testCases, vi } from "vitest";
import {
  GitChangesContent,
  GitChangesRoute,
  GitChangesRedirectRoute,
  MobilePortraitGate,
  gitChangesSearchSchema,
  openGitChanges,
} from "./index";
import { Dialog } from "../shadcn/dialog";
import { changes, fileChange } from "./fixtures.test-support";
import { gitPreloadDelayMs } from "./resources";

const resources = vi.hoisted(() => ({ useResource: vi.fn() }));
vi.mock("../utils/overmux-hooks", () => resources);
vi.mock("./viewer", () => ({
  GitViewer: ({
    selected,
  }: {
    selected?: { comparison: string; path: string };
  }) => (
    <div>
      Git viewer {selected ? `${selected.comparison}:${selected.path}` : ""}
    </div>
  ),
}));
Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });
let mounts = 0;
const restoredFocus = vi.fn();
const Terminal = () => {
  useEffect(() => {
    mounts += 1;
  }, []);
  return (
    <>
      <div data-terminal>Terminal</div>
      <GitChangesRoute cwd="/repo" onCloseAutoFocus={restoredFocus} />
    </>
  );
};
let root: ReturnType<typeof createRoot>;
let container: HTMLDivElement;
let history: ReturnType<typeof createMemoryHistory>;
const setup = async (path = "/tmux") => {
  mounts = 0;
  restoredFocus.mockClear();
  vi.stubGlobal("matchMedia", () => ({ matches: false }));
  resources.useResource.mockImplementation(({ id }) => ({
    status: "success",
    data:
      id === "gitRepository"
        ? { displayPath: "repo", isWorktree: false, repoRoot: "/repo" }
        : changes({ staged: [fileChange("a.ts")], unstaged: [] }),
  }));
  const rootRoute = createRootRoute({ component: Outlet });
  const tmux = createRoute({
    getParentRoute: () => rootRoute,
    path: "tmux",
    component: Terminal,
    validateSearch: gitChangesSearchSchema,
  });
  const git = createRoute({
    getParentRoute: () => rootRoute,
    path: "git/$mode",
    component: GitChangesRedirectRoute,
  });
  history = createMemoryHistory({ initialEntries: [path] });
  const router = createRouter({
    history,
    routeTree: rootRoute.addChildren([tmux, git]),
  });
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
  await act(async () => root.render(<RouterProvider router={router} />));
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, gitPreloadDelayMs));
  });
  return router;
};
afterEach(async () => {
  await act(async () => root.unmount());
  container.remove();
  history.destroy();
  vi.unstubAllGlobals();
});

testCases.each([
  { comparison: "workingTree" as const, path: "/git/base", closeKey: "q" },
  {
    comparison: "uncommitted" as const,
    path: "/git/changes",
    closeKey: "Escape",
  },
])(
  "$comparison stays over the mounted terminal and dismisses with $closeKey",
  async ({ comparison, path, closeKey }) => {
    const router = await setup();
    const terminal = container.querySelector("[data-terminal]");
    await act(async () => {
      await openGitChanges(
        router as Parameters<typeof openGitChanges>[0],
        comparison,
      );
    });
    expect(router.state.location.pathname).toBe("/tmux");
    expect(router.state.location.maskedLocation?.pathname).toBe(path);
    expect(document.querySelector("[role=dialog]")?.textContent).toContain(
      "Git viewer",
    );
    expect(resources.useResource).toHaveBeenCalledWith(
      expect.objectContaining({
        id: "gitChanges",
        input: expect.objectContaining({
          detailLevel: "hunks",
          repoRoot: "/repo",
        }),
      }),
    );
    await act(async () => {
      document.querySelector("[role=dialog]")?.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: closeKey,
          bubbles: true,
          cancelable: true,
        }),
      );
    });
    expect(router.state.location.search).not.toHaveProperty("gitChanges");
    expect(container.querySelector("[data-terminal]")).toBe(terminal);
    expect(mounts).toBe(1);
    await vi.waitFor(() => expect(restoredFocus).toHaveBeenCalled());
  },
);

testCases(
  "direct base links redirect into the masked terminal overlay",
  async () => {
    const router = await setup("/git/base");
    expect(router.state.location.pathname).toBe("/tmux");
    expect(router.state.location.search).toEqual({
      gitChanges: { comparison: "workingTree" },
    });
    expect(document.querySelector("[role=dialog]")?.textContent).toContain(
      "Changes vs origin/main",
    );
  },
);

testCases(
  "portrait gate asks users to rotate when orientation lock is unavailable",
  async () => {
    await setup();
    await act(async () =>
      root.render(
        <Dialog open>
          <MobilePortraitGate />
        </Dialog>,
      ),
    );
    const button = container.querySelector<HTMLButtonElement>("button");
    expect(button?.textContent).toBe("Switch to landscape");
    await act(async () => button?.click());
    expect(button?.textContent).toBe("Rotate your device to landscape");
  },
);

testCases(
  "mobile file buttons traverse unstaged then staged and disable when empty",
  async () => {
    await setup();
    const data = changes({
      staged: [fileChange("staged.ts")],
      unstaged: [fileChange("unstaged.ts")],
    });
    await act(async () =>
      root.render(
        <Dialog open>
          <GitChangesContent
            data={data}
            mode="uncommitted"
            repoPath="repo"
            title="Local changes"
          />
        </Dialog>,
      ),
    );
    const next = container.querySelector<HTMLButtonElement>(
      '[aria-label="Next changed file"]',
    );
    expect(next?.disabled).toBe(false);
    expect(container.textContent).toContain("unstaged:unstaged.ts");
    await act(async () => next?.click());
    expect(container.textContent).toContain("staged:staged.ts");
    await act(async () =>
      root.render(
        <Dialog open>
          <GitChangesContent
            data={changes({ staged: [], unstaged: [] })}
            mode="uncommitted"
            repoPath="repo"
            title="Local changes"
          />
        </Dialog>,
      ),
    );
    expect(
      container.querySelector<HTMLButtonElement>(
        '[aria-label="Previous changed file"]',
      )?.disabled,
    ).toBe(true);
  },
);

testCases(
  "uses one compact header without ahead or behind counts",
  async () => {
    const router = await setup();
    await act(async () => {
      await openGitChanges(
        router as Parameters<typeof openGitChanges>[0],
        "uncommitted",
      );
    });
    const header = document.querySelector("[role=dialog] header");
    expect(header?.textContent).toContain("Local changes · repo · feature");
    expect(header?.textContent).toMatch(/[↑↓]/);
  },
);
