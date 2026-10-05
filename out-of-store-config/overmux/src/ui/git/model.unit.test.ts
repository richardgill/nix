import { parsePatchFiles } from "@pierre/diffs";
import { expect, test as testCases } from "vitest";
import {
  comparisonInput,
  displayBranch,
  displayDiff,
  displayPatch,
  navigateChange,
  orderedChanges,
  resolveSelection,
} from "./model";

import { changes, fileChange } from "./fixtures.test-support";

testCases("base compares origin/main directly, not its merge base", () => {
  expect(comparisonInput("workingTree")).toEqual({
    workingTree: {
      base: { kind: "commit", ref: "origin/main" },
      target: { kind: "workingTree" },
    },
  });
  expect(comparisonInput("uncommitted")).toEqual({
    staged: {
      base: { kind: "commit", ref: "HEAD" },
      target: { kind: "index" },
    },
    unstaged: { base: { kind: "index" }, target: { kind: "workingTree" } },
  });
});

testCases(
  "navigation keeps duplicate paths in separate comparisons and follows tree order",
  () => {
    const entries = orderedChanges(
      changes({
        unstaged: [fileChange("src/a.ts")],
        staged: [
          fileChange("z.ts"),
          fileChange("src/b.ts"),
          fileChange("src/a.ts"),
        ],
      }),
    );
    expect(entries.map(({ comparison, path }) => [comparison, path])).toEqual([
      ["unstaged", "src/a.ts"],
      ["staged", "src/a.ts"],
      ["staged", "src/b.ts"],
      ["staged", "z.ts"],
    ]);
    expect(navigateChange(entries, entries[0], -1)).toBe(entries[3]);
    expect(navigateChange(entries, entries[3], 1)).toBe(entries[0]);
    expect(
      resolveSelection(entries, { comparison: "unstaged", path: "src/a.ts" }),
    ).toBe(entries[0]);
    expect(
      resolveSelection(entries, { comparison: "staged", path: "removed.ts" }),
    ).toBe(entries[0]);
    expect(navigateChange([], undefined, 1)).toBeUndefined();
  },
);

testCases.each([
  {
    branch: { name: "feature", unborn: false },
    isWorktree: true,
    repoRoot: "/code/feature",
    expected: undefined,
  },
  {
    branch: { name: "feature", unborn: false },
    isWorktree: false,
    repoRoot: "/code/feature",
    expected: "feature",
  },
  {
    branch: { name: "feature", unborn: false },
    isWorktree: true,
    repoRoot: "/code/other",
    expected: "feature",
  },
  {
    branch: { name: null, unborn: true },
    isWorktree: true,
    repoRoot: "/code/feature",
    expected: "Detached HEAD (no commits)",
  },
])(
  "displays a branch only when its worktree folder differs",
  ({ branch, isWorktree, repoRoot, expected }) => {
    expect(
      displayBranch({
        branch: { ahead: 0, behind: 0, upstream: null, ...branch },
        isWorktree,
        repoRoot,
      }),
    ).toBe(expected);
  },
);

testCases.each([
  "src/main.ts",
  "space name.ts",
  'quoted"file.ts',
  "日本語.ts",
  "line\nbreak.ts",
])("hunks are rendered at their real coordinates: %s", (path) => {
  const patch = displayPatch(fileChange(path));
  expect(patch).not.toContain("oldContent");
  const parsed = displayDiff(fileChange(path));
  expect(parsed).toBeDefined();
  expect(parsed?.name).toBe(path);
  expect(parsed?.hunks[0]?.deletionStart).toBe(40);
  expect(parsed?.additionLines.join("")).toContain("after");
  expect(parsed?.deletionLines.join("")).toContain("before");
});

testCases.each(["added", "deleted", "renamed", "untracked"] as const)(
  "display patch handles %s files",
  (status) => {
    const change = fileChange("new.ts", {
      status,
      previousPath: status === "renamed" ? "old.ts" : undefined,
      diff: {
        hunks: [
          {
            oldStart: status === "added" || status === "untracked" ? 0 : 1,
            oldCount: status === "added" || status === "untracked" ? 0 : 1,
            newStart: status === "deleted" ? 0 : 1,
            newCount: status === "deleted" ? 0 : 1,
            lines: [
              ...(status === "added" || status === "untracked"
                ? []
                : [{ kind: "removed" as const, oldLine: 1, text: "old" }]),
              ...(status === "deleted"
                ? []
                : [{ kind: "added" as const, newLine: 1, text: "new" }]),
            ],
          },
        ],
      },
    });
    expect(parsePatchFiles(displayPatch(change))[0]?.files).toHaveLength(1);
  },
);
