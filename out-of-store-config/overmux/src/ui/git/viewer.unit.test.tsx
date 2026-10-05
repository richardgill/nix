import { act, useState } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, beforeEach, expect, test as testCases, vi } from "vitest";
import { skipToken } from "overmux/client";
import type { FileDiffMetadata } from "@pierre/diffs";
import type { GitDiff } from "@overmux/git/shared";
import { GitViewer } from "./viewer";
import { GitChangesContent } from "./index";
import { Dialog } from "../shadcn/dialog";
import { orderedChanges, resolveSelection, type FileSelection } from "./model";
import { changes, fileChange } from "./fixtures.test-support";

const resource = vi.hoisted(() => ({ useResource: vi.fn() }));
vi.mock("../utils/overmux-hooks", () => resource);
vi.mock("./pierre-diff", () => ({
  PierrePatchDiff: ({
    fileDiff,
    diffStyle,
  }: {
    fileDiff: FileDiffMetadata;
    diffStyle: string;
  }) => (
    <pre data-style={diffStyle}>
      {fileDiff.deletionLines.join("")}
      {fileDiff.additionLines.join("")}
    </pre>
  ),
  PierreFileDiff: ({
    newContent,
    expandUnchanged,
  }: {
    newContent: string;
    expandUnchanged: boolean;
  }) => <pre data-whole={expandUnchanged}>{newContent}</pre>,
}));
vi.mock("./file-tree", () => ({
  GitFileTree: ({
    changes: files,
    onSelect,
  }: {
    changes: { path: string }[];
    onSelect: (path: string) => void;
  }) => (
    <div>
      {files.map(({ path }) => (
        <button key={path} onClick={() => onSelect(path)}>
          {path}
        </button>
      ))}
    </div>
  ),
}));

Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });
let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
const selections = new Map<string, FileSelection>();
const Viewer = ({
  data,
  mode,
}: {
  data: ReturnType<typeof changes>;
  mode: "uncommitted" | "workingTree";
}) => {
  const key = `${data.repoRoot}:${mode}`;
  const [selection, setSelection] = useState(() => selections.get(key));
  const select = (next: FileSelection | undefined) => {
    if (!next) return;
    const value = { comparison: next.comparison, path: next.path };
    selections.set(key, value);
    setSelection(value);
  };
  return (
    <GitViewer
      data={data}
      onSelectionChange={select}
      selected={resolveSelection(orderedChanges(data), selection)}
    />
  );
};

beforeEach(() => {
  vi.stubGlobal("matchMedia", () => ({ matches: true }));
  resource.useResource.mockReset().mockReturnValue(undefined);
  selections.clear();
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
});
afterEach(async () => {
  await act(async () => root.unmount());
  container.remove();
  vi.unstubAllGlobals();
});
const render = async (
  data: ReturnType<typeof changes>,
  mode: "uncommitted" | "workingTree" = "uncommitted",
) => {
  await act(async () =>
    root.render(
      <Viewer data={data} key={`${data.repoRoot}:${mode}`} mode={mode} />,
    ),
  );
};
const press = async (key: string, modifiers: KeyboardEventInit = {}) => {
  await act(async () =>
    document.activeElement?.dispatchEvent(
      new KeyboardEvent("keydown", {
        key,
        bubbles: true,
        cancelable: true,
        ...modifiers,
      }),
    ),
  );
};
const click = async (text: string) => {
  const button = [...container.querySelectorAll("button")].find(
    (element) => element.textContent === text,
  );
  expect(button).toBeDefined();
  await act(async () => button?.click());
};
const path = () =>
  container.querySelector(".git-diff-filename h2")?.textContent;

testCases(
  "mobile layout removes the file tree and its focusable resizer",
  async () => {
    vi.stubGlobal("matchMedia", () => ({ matches: false }));
    await render(changes({ staged: [fileChange("a.ts")] }, "/mobile"));
    expect(container.querySelector(".git-sidebar")).toBeNull();
    expect(container.querySelector("[role=separator]")).toBeNull();
    expect(container.querySelector(".git-viewer")?.className).toBe(
      "git-viewer",
    );
  },
);

testCases(
  "landscape touch swipes share header navigation and remembered selection",
  async () => {
    vi.stubGlobal("matchMedia", (query: string) => ({
      matches:
        query.includes("reduced-motion") || query === "(pointer: coarse)",
    }));
    HTMLElement.prototype.setPointerCapture = vi.fn();
    HTMLElement.prototype.hasPointerCapture = vi.fn(() => false);
    const data = changes(
      {
        unstaged: [fileChange("unstaged.ts")],
        staged: [fileChange("staged.ts")],
      },
      "/swipe-memory",
    );
    const content = (
      <Dialog open>
        <GitChangesContent
          data={data}
          mode="uncommitted"
          title="Local changes"
        />
      </Dialog>
    );
    await act(async () => root.render(content));
    const pane = container.querySelector<HTMLElement>(".git-diff")!;
    const swipe = container.querySelector<HTMLElement>(".git-diff-swipe")!;
    Object.defineProperty(swipe, "clientWidth", { value: 900 });
    expect(swipe.dataset.swipeEnabled).toBe("true");
    pane.scrollTop = 100;
    for (const [type, clientX] of [
      ["pointerdown", 500],
      ["pointermove", 300],
      ["pointerup", 300],
    ] as const) {
      await act(async () =>
        pane.dispatchEvent(
          new PointerEvent(type, {
            bubbles: true,
            cancelable: true,
            pointerType: "touch",
            pointerId: 1,
            isPrimary: true,
            clientX,
          }),
        ),
      );
    }
    expect(path()).toBe("staged.ts");
    expect(container.querySelector(".git-diff")).toBe(pane);
    expect(pane.scrollTop).toBe(0);
    await act(async () => root.render(null));
    await act(async () => root.render(content));
    expect(path()).toBe("staged.ts");
    await act(async () =>
      container
        .querySelector<HTMLButtonElement>('[aria-label="Next changed file"]')
        ?.click(),
    );
    expect(path()).toBe("unstaged.ts");
  },
);

testCases(
  "hunks stay the default; only explicit expansion subscribes to full contents",
  async () => {
    const change = fileChange("a.ts");
    const data = changes({ unstaged: [change] }, "/demand");
    await render(data);
    expect(resource.useResource).toHaveBeenLastCalledWith({
      id: "gitDiff",
      input: skipToken,
    });
    expect(container.querySelector("pre")?.dataset.style).toBe("split");
    expect(container.querySelector("pre")?.textContent).toContain("before");
    await click("Context");
    expect(resource.useResource).toHaveBeenLastCalledWith({
      id: "gitDiff",
      input: change.diffParams,
    });
    const full: GitDiff = {
      file: change.path,
      binary: false,
      oldContent: "real context\nbefore\n",
      newContent: "real context\nafter\n",
      hunks: change.diff!.hunks,
    };
    resource.useResource.mockReturnValue({ status: "ready", data: full });
    await render(data);
    expect(container.querySelector("pre")?.textContent).toContain(
      "real context",
    );
    await click("Full");
    expect(container.querySelector("pre")?.dataset.whole).toBe("true");
  },
);

testCases(
  "Tab and tree arrows traverse comparisons, retain selection, and follow live changes",
  async () => {
    const data = changes(
      {
        unstaged: [fileChange("a.ts"), fileChange("b.ts")],
        staged: [fileChange("a.ts")],
      },
      "/navigation",
    );
    await render(data);
    expect(
      [...container.querySelectorAll(".git-sidebar h2")].map(
        (heading) => heading.textContent,
      ),
    ).toEqual(["Unstaged (2)+2−2", "Staged (1)+1−1"]);
    expect(
      container.querySelector(".git-comparison-label")?.textContent,
    ).toContain("Unstaged");
    await press("Tab");
    expect(path()).toBe("b.ts");
    expect(
      container.querySelector(".git-comparison-label")?.textContent,
    ).toContain("Unstaged");
    await press("Tab");
    expect(
      container.querySelector(".git-comparison-label")?.textContent,
    ).toContain("Staged");
    await press("Tab", { shiftKey: true });
    expect(path()).toBe("b.ts");
    await press("ArrowLeft", { ctrlKey: true, shiftKey: true });
    expect(document.activeElement).toBe(
      container.querySelector(".git-sidebar"),
    );
    await press("ArrowDown");
    expect(path()).toBe("a.ts");
    expect(
      container.querySelector(".git-comparison-label")?.textContent,
    ).toContain("Staged");
    await render(
      changes({ workingTree: [fileChange("other.ts")] }, "/navigation"),
      "workingTree",
    );
    await render(data);
    expect(path()).toBe("a.ts");
    await render(changes({ unstaged: [fileChange("new.ts")] }, "/navigation"));
    expect(path()).toBe("new.ts");
  },
);

testCases(
  "sidebar headings sum available line stats and retain file counts",
  async () => {
    await render(
      changes(
        {
          unstaged: [
            fileChange("a.ts", { lineStats: { added: 2, deleted: 3 } }),
            fileChange("image.png", { binary: true, lineStats: null }),
            fileChange("b.ts", { lineStats: { added: 5, deleted: 7 } }),
          ],
          staged: [fileChange("binary.png", { binary: true, lineStats: null })],
          workingTree: [
            fileChange("base.ts", { lineStats: { added: 4, deleted: 2 } }),
          ],
        },
        "/sidebar-stats",
      ),
    );
    const headings = [...container.querySelectorAll(".git-sidebar h2")];
    expect(headings.map((heading) => heading.textContent)).toEqual([
      "Unstaged (3)+7−10",
      "Staged (1)",
      "Changes against origin/main (1)+4−2",
    ]);
    expect(
      headings[0]?.querySelector(".git-line-stats")?.getAttribute("aria-label"),
    ).toBe("7 additions, 10 deletions");
    expect(headings[1]?.querySelector(".git-line-stats")).toBeNull();
    expect(
      headings[1]?.querySelector(".git-sidebar-file-count")?.textContent,
    ).toBe("(1)");
  },
);

testCases(
  "focus and keyboard resize work without hijacking dismissal",
  async () => {
    await render(changes({ staged: [fileChange("a.ts")] }, "/focus"));
    await press("ArrowLeft", { ctrlKey: true, shiftKey: true });
    await press("F6");
    expect(document.activeElement?.getAttribute("role")).toBe("separator");
    await press("ArrowRight");
    expect(
      container
        .querySelector("[role=separator]")
        ?.getAttribute("aria-valuenow"),
    ).toBe("120");
    await press("ArrowRight", { ctrlKey: true, shiftKey: true });
    expect(document.activeElement).toBe(container.querySelector(".git-diff"));
    const event = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });
    document.activeElement?.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(false);
  },
);

testCases.each([
  {
    label: "binary",
    change: fileChange("image.png", { binary: true, lineStats: null }),
    expected: "Binary file",
  },
  {
    label: "rename only",
    change: fileChange("new.ts", {
      status: "renamed",
      previousPath: "old.ts",
      diff: { hunks: [] },
    }),
    expected: "No textual changes",
  },
  {
    label: "conflict",
    change: fileChange("conflict.ts", { status: "conflicted" }),
    expected: "Unresolved conflict",
  },
])(
  "handles $label without mutation actions",
  async ({ change, expected, label }) => {
    await render(changes({ unstaged: [change] }, `/state-${label}`));
    expect(container.textContent).toContain(expected);
    expect(
      [...container.querySelectorAll("button")].map(
        (button) => button.textContent,
      ),
    ).not.toEqual(
      expect.arrayContaining([
        expect.stringMatching(/^(Discard|Unstage|Stage)( |$)/),
      ]),
    );
  },
);

testCases(
  "real GitViewer renders a selected file without a memoryKey reference",
  async () => {
    const data = changes({ unstaged: [fileChange("a.ts")] }, "/memory-key");
    await act(async () =>
      root.render(
        <GitViewer
          data={data}
          onSelectionChange={() => undefined}
          selected={resolveSelection(orderedChanges(data))}
        />,
      ),
    );
    expect(path()).toBe("a.ts");
  },
);

testCases.each([
  {
    label: "local modified",
    comparison: "unstaged",
    change: fileChange("a.ts"),
    comparisonLabel: undefined,
    localLabel: "Unstaged",
    statusLabel: undefined,
  },
  {
    label: "base modified",
    comparison: "workingTree",
    change: fileChange("a.ts"),
    comparisonLabel: undefined,
    localLabel: undefined,
    statusLabel: undefined,
  },
  {
    label: "added",
    comparison: "unstaged",
    change: fileChange("new.ts", { status: "added" }),
    comparisonLabel: undefined,
    localLabel: "Unstaged",
    statusLabel: "Added",
  },
  {
    label: "deleted",
    comparison: "unstaged",
    change: fileChange("old.ts", { status: "deleted" }),
    comparisonLabel: undefined,
    localLabel: "Unstaged",
    statusLabel: "Deleted",
  },
  {
    label: "untracked",
    comparison: "unstaged",
    change: fileChange("new.ts", { status: "untracked" }),
    comparisonLabel: undefined,
    localLabel: "Unstaged",
    statusLabel: "Untracked",
  },
  {
    label: "conflict",
    comparison: "unstaged",
    change: fileChange("conflict.ts", { status: "conflicted" }),
    comparisonLabel: undefined,
    localLabel: "Unstaged",
    statusLabel: "Conflict",
  },
])(
  "file header presents $label metadata without redundant comparison text",
  async ({ comparison, change, localLabel, statusLabel }) => {
    await render(changes({ [comparison]: [change] }, `/header-${comparison}`));
    expect(container.querySelector(".git-comparison-label")?.textContent).toBe(
      localLabel,
    );
    expect(container.querySelector(".git-change-status")?.textContent).toBe(
      statusLabel,
    );
    expect(container.querySelector(".git-line-stats")?.textContent).toBe(
      "+1−1",
    );
  },
);

testCases(
  "rename and binary file headers preserve paths and appropriate controls",
  async () => {
    const renamed = fileChange("new.ts", {
      status: "renamed",
      previousPath: "old.ts",
    });
    await render(changes({ staged: [renamed] }, "/rename"));
    expect(path()).toBe("old.ts → new.ts");
    expect(
      container.querySelector(".git-diff-filename")?.getAttribute("title"),
    ).toBe("old.ts → new.ts");
    expect(container.querySelector(".git-change-status")?.textContent).toBe(
      "Renamed",
    );
    expect(
      [...container.querySelectorAll("button")].map(
        (button) => button.textContent,
      ),
    ).toEqual(expect.arrayContaining(["Context", "Full"]));

    await render(
      changes(
        {
          staged: [fileChange("image.png", { binary: true, lineStats: null })],
        },
        "/binary-header",
      ),
    );
    expect(container.querySelector(".git-binary-label")?.textContent).toBe(
      "Binary",
    );
    expect(container.querySelector(".git-line-stats")).toBeNull();
    expect(
      [...container.querySelectorAll("button")].map(
        (button) => button.textContent,
      ),
    ).not.toEqual(expect.arrayContaining(["Context", "Full"]));
  },
);

testCases(
  "empty, loading full contents, and expansion errors keep useful hunks visible",
  async () => {
    await render(changes({ staged: [], unstaged: [] }, "/empty"));
    expect(container.textContent).toContain("No changes in these comparisons");
    const data = changes({ unstaged: [fileChange("a.ts")] }, "/error");
    await render(data);
    resource.useResource.mockReturnValue({ status: "pending" });
    await click("Full");
    expect(container.textContent).toContain("Loading full file contents");
    expect(container.querySelector("pre")?.textContent).toContain("before");
    resource.useResource.mockReturnValue({
      status: "error",
      error: new Error("unavailable"),
    });
    await render(data);
    expect(container.querySelector("[role=alert]")?.textContent).toContain(
      "unavailable",
    );
    expect(container.querySelector("pre")?.textContent).toContain("before");
  },
);
