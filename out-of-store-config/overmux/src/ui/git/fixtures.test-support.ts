import type { GitChanges, GitFileChange } from "@overmux/git/shared";

export const fileChange = (
  path: string,
  overrides: Partial<GitFileChange> = {},
): GitFileChange => ({
  path,
  status: "modified",
  binary: false,
  lineStats: { added: 1, deleted: 1 },
  diffParams: {
    repoRoot: "/repo",
    file: path,
    comparison: { base: { kind: "index" }, target: { kind: "workingTree" } },
  },
  diff: {
    hunks: [
      {
        oldStart: 40,
        oldCount: 2,
        newStart: 40,
        newCount: 2,
        lines: [
          { kind: "context", oldLine: 40, newLine: 40, text: "same" },
          { kind: "removed", oldLine: 41, text: "before" },
          { kind: "added", newLine: 41, text: "after" },
        ],
      },
    ],
  },
  ...overrides,
});

export const changes = (
  comparisons: GitChanges["comparisons"],
  repoRoot = "/repo",
): GitChanges => ({
  repoRoot,
  comparisons,
  branch: {
    name: "feature",
    upstream: null,
    ahead: 0,
    behind: 0,
    unborn: false,
  },
});
