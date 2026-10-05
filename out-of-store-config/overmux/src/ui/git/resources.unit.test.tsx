import { act, useEffect } from "react";
import { createRoot } from "react-dom/client";
import { skipToken } from "overmux/client";
import { afterEach, beforeEach, expect, test as testCases, vi } from "vitest";

import { GitChangesRoute } from "./index";
import { changes, fileChange } from "./fixtures.test-support";
import { comparisonInput, type ComparisonMode } from "./model";
import { gitPreloadDelayMs } from "./resources";

const mocks = vi.hoisted(() => ({
  useResource: vi.fn(),
  useRouteState: vi.fn(),
}));
vi.mock("../utils/overmux-hooks", () => ({ useResource: mocks.useResource }));
vi.mock("../utils/use-route-state", () => ({
  useRouteState: mocks.useRouteState,
}));
vi.mock("./viewer", () => ({
  GitViewer: ({ data }: { data: { repoRoot: string } }) => (
    <div>Hunks for {data.repoRoot}</div>
  ),
}));

// Model the runtime's per-hook subscription ownership, not a deduplicating hook mock.
const subscriptions = new Set<string>();
const starts: string[] = [];
const stops: string[] = [];
const results = new Map<string, object>();
const retry = vi.fn();
const useTestResource = ({ id, input }: { id: string; input: unknown }) => {
  const key = input === skipToken ? undefined : JSON.stringify({ id, input });
  useEffect(() => {
    if (!key) return;
    expect(subscriptions.has(key), `duplicate subscription: ${key}`).toBe(
      false,
    );
    subscriptions.add(key);
    starts.push(key);
    return () => {
      subscriptions.delete(key);
      stops.push(key);
    };
  }, [key]);
  if (!key) return undefined;
  if (results.has(key)) return results.get(key);
  const { cwd, repoRoot } = input as { cwd?: string; repoRoot?: string };
  return {
    status: "success",
    refetch: retry,
    data:
      id === "gitRepository"
        ? {
            repoRoot: cwd?.startsWith("/repo/sub") ? "/repo" : cwd,
            displayPath: cwd,
            isWorktree: false,
          }
        : {
            ...changes({ staged: [fileChange("a.ts")], unstaged: [] }),
            repoRoot,
          },
  };
};

Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });
let root: ReturnType<typeof createRoot>;
let container: HTMLDivElement;
const render = async (cwd?: string, mode?: ComparisonMode) => {
  mocks.useRouteState.mockReturnValue([
    mode ? { comparison: mode } : undefined,
    vi.fn(),
  ]);
  await act(async () => root.render(<GitChangesRoute cwd={cwd} />));
};
const advance = async (ms = gitPreloadDelayMs) => {
  await act(async () => vi.advanceTimersByTimeAsync(ms));
};
const changeStarts = () =>
  starts.filter((key) => JSON.parse(key).id === "gitChanges");
const repositoryKey = (cwd: string) =>
  JSON.stringify({ id: "gitRepository", input: { cwd } });
const changesKey = (repoRoot: string, mode: ComparisonMode) =>
  JSON.stringify({
    id: "gitChanges",
    input: {
      comparisons: comparisonInput(mode),
      detailLevel: "hunks",
      repoRoot,
    },
  });

beforeEach(() => {
  vi.useFakeTimers();
  vi.stubGlobal("matchMedia", () => ({ matches: false }));
  subscriptions.clear();
  starts.length = 0;
  stops.length = 0;
  results.clear();
  retry.mockClear();
  mocks.useResource.mockImplementation(useTestResource);
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
});
afterEach(async () => {
  await act(async () => root.unmount());
  expect(subscriptions.size).toBe(0);
  container.remove();
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

testCases(
  "preloads exactly both hunk comparisons after the delay, without a modal or gitDiff",
  async () => {
    await render("/repo");
    await advance(gitPreloadDelayMs - 1);
    expect(changeStarts()).toEqual([]);
    await advance(1);
    expect(changeStarts()).toEqual([
      changesKey("/repo", "uncommitted"),
      changesKey("/repo", "workingTree"),
    ]);
    expect(starts.map((key) => JSON.parse(key).id)).toEqual([
      "gitRepository",
      "gitChanges",
      "gitChanges",
    ]);
    expect(document.querySelector("[role=dialog]")).toBeNull();
  },
);

testCases(
  "opening, changing mode, and closing the modal reuse the two existing owners",
  async () => {
    await render("/repo");
    await advance();
    const initialStarts = [...starts];
    for (const mode of ["uncommitted", "workingTree", undefined] as const) {
      await render("/repo", mode);
      expect(starts).toEqual(initialStarts);
      if (mode)
        expect(document.querySelector("[role=dialog]")?.textContent).toContain(
          "Hunks for /repo",
        );
    }
    expect(stops).toEqual([]);
  },
);

testCases(
  "switching repos hides stale hunks immediately, debounces transient panes, and cleans up",
  async () => {
    await render("/repo", "uncommitted");
    await advance();
    await render("/transient", "uncommitted");
    expect(document.querySelector("[role=dialog]")?.textContent).not.toContain(
      "Hunks for /repo",
    );
    await advance(100);
    await render("/other", "uncommitted");
    await advance();
    expect(changeStarts()).toEqual([
      changesKey("/repo", "uncommitted"),
      changesKey("/repo", "workingTree"),
      changesKey("/other", "uncommitted"),
      changesKey("/other", "workingTree"),
    ]);
    expect(stops).toContain(changesKey("/repo", "uncommitted"));
    expect(stops).toContain(changesKey("/repo", "workingTree"));
    expect(document.querySelector("[role=dialog]")?.textContent).toContain(
      "Hunks for /other",
    );
  },
);

testCases(
  "same-root pane cwd discovery retains watches without showing data during discovery",
  async () => {
    await render("/repo", "uncommitted");
    await advance();
    results.set(repositoryKey("/repo/sub"), {
      status: "pending",
      refetch: retry,
    });
    await render("/repo/sub", "uncommitted");
    expect(document.querySelector("[role=dialog]")?.textContent).toContain(
      "Finding git repository",
    );
    expect(document.querySelector("[role=dialog]")?.textContent).not.toContain(
      "Hunks for",
    );
    await advance(50);
    results.clear();
    await render("/repo/sub", "uncommitted");
    await advance();
    expect(changeStarts()).toHaveLength(2);
    expect(stops.filter((key) => JSON.parse(key).id === "gitChanges")).toEqual(
      [],
    );
    expect(document.querySelector("[role=dialog]")?.textContent).toContain(
      "Hunks for /repo",
    );
  },
);

testCases(
  "slow discovery releases old watches and late old results cannot surface",
  async () => {
    await render("/repo", "uncommitted");
    await advance();
    results.set(repositoryKey("/other"), { status: "pending", refetch: retry });
    await render("/other", "uncommitted");
    await advance();
    expect(
      [...subscriptions].filter((key) => JSON.parse(key).id === "gitChanges"),
    ).toEqual([]);
    results.set(changesKey("/repo", "uncommitted"), {
      status: "success",
      data: changes({ staged: [], unstaged: [] }),
    });
    await render("/other", "uncommitted");
    expect(document.querySelector("[role=dialog]")?.textContent).not.toContain(
      "Hunks for",
    );
    results.delete(repositoryKey("/other"));
    await render("/other", "uncommitted");
    await advance();
    expect(document.querySelector("[role=dialog]")?.textContent).toContain(
      "Hunks for /other",
    );
  },
);

testCases.each(["repository", "changes"] as const)(
  "background %s errors are quiet, but the modal exposes retry",
  async (failure) => {
    const key =
      failure === "repository"
        ? repositoryKey("/repo")
        : changesKey("/repo", "uncommitted");
    results.set(key, {
      status: "error",
      error: new Error("Not a Git repository or comparison unavailable"),
      refetch: retry,
    });
    await render("/repo");
    await advance();
    expect(document.querySelector("[role=alert]")).toBeNull();
    if (failure === "repository") expect(changeStarts()).toEqual([]);
    await render("/repo", "uncommitted");
    expect(document.querySelector("[role=alert]")?.textContent).toContain(
      "Not a Git repository",
    );
    await act(async () =>
      document.querySelector<HTMLButtonElement>("[role=alert] button")?.click(),
    );
    expect(retry).toHaveBeenCalledOnce();
    results.clear();
    await render("/repo", "uncommitted");
    await advance();
    expect(document.querySelector("[role=dialog]")?.textContent).toContain(
      "Hunks for /repo",
    );
  },
);

testCases(
  "leaving a repository for a nonrepo or no pane stops both watches",
  async () => {
    await render("/repo");
    await advance();
    results.set(repositoryKey("/tmp"), {
      status: "error",
      error: new Error("Not a git repository"),
      refetch: retry,
    });
    await render("/tmp");
    await advance();
    expect([...subscriptions]).toEqual([repositoryKey("/tmp")]);
    await render();
    expect([...subscriptions]).toEqual([]);
    await advance();
    expect(changeStarts()).toHaveLength(2);
  },
);

testCases("unmount cancels a queued preload", async () => {
  await render("/repo");
  await act(async () => root.render(null));
  await advance();
  expect(starts).toEqual([repositoryKey("/repo")]);
});
