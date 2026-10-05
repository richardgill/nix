import type {
  GitChanges,
  GitChangesInput,
  GitFileChange,
} from "@overmux/git/shared";
import { prepareFileTreeInput } from "@pierre/trees";
import { getSingularPatch } from "@pierre/diffs";

export type ComparisonMode = "workingTree" | "uncommitted";
export type FileSelection = { comparison: string; path: string };
export type ChangeEntry = FileSelection & { change: GitFileChange };

export const comparisonInput = (
  mode: ComparisonMode,
): GitChangesInput["comparisons"] =>
  mode === "workingTree"
    ? {
        workingTree: {
          base: { kind: "commit", ref: "origin/main" },
          target: { kind: "workingTree" },
        },
      }
    : {
        staged: {
          base: { kind: "commit", ref: "HEAD" },
          target: { kind: "index" },
        },
        unstaged: { base: { kind: "index" }, target: { kind: "workingTree" } },
      };

export const comparisonTitle = (comparison: string) =>
  ({
    staged: "Staged",
    unstaged: "Unstaged",
    workingTree: "Changes against origin/main",
  })[comparison] ?? comparison;

const comparisonOrder = (comparison: string) =>
  ({ unstaged: 0, staged: 1 })[comparison] ?? 2;

export const orderedComparisons = (comparisons: GitChanges["comparisons"]) =>
  Object.entries(comparisons).sort(
    ([left], [right]) => comparisonOrder(left) - comparisonOrder(right),
  );

export const displayBranch = ({
  branch,
  isWorktree,
  repoRoot,
}: {
  branch: GitChanges["branch"];
  isWorktree: boolean;
  repoRoot: string;
}) => {
  const name = branch.name ?? "Detached HEAD";
  const folder = repoRoot.split("/").filter(Boolean).at(-1);
  if (isWorktree && branch.name === folder) return undefined;
  return `${name}${branch.unborn ? " (no commits)" : ""}`;
};

// Keep keyboard traversal in the same directory-first order as Pierre's tree.
// https://github.com/richardgill/overmux/pull/17
export const orderedChanges = (data: GitChanges): ChangeEntry[] =>
  orderedComparisons(data.comparisons).flatMap(([comparison, changes]) => {
    const byPath = new Map(changes.map((change) => [change.path, change]));
    return prepareFileTreeInput(changes.map(({ path }) => path)).paths.flatMap(
      (path) => {
        const change = byPath.get(path);
        return change ? [{ comparison, path, change }] : [];
      },
    );
  });

export const sameSelection = (
  entry: FileSelection,
  selection?: FileSelection,
) =>
  entry.comparison === selection?.comparison && entry.path === selection.path;

export const resolveSelection = (
  entries: ChangeEntry[],
  selection?: FileSelection,
) => entries.find((entry) => sameSelection(entry, selection)) ?? entries[0];

export const navigateChange = (
  entries: ChangeEntry[],
  selection: FileSelection | undefined,
  direction: 1 | -1,
) => {
  if (!entries.length) return undefined;
  const index = entries.findIndex((entry) => sameSelection(entry, selection));
  return entries[
    index < 0
      ? direction === 1
        ? 0
        : entries.length - 1
      : (index + direction + entries.length) % entries.length
  ];
};

// Display-only patch: hunk text does not contain EOF terminator metadata.
// Never use this to apply changes; createGitPatch requires authoritative full contents.
export const displayPatch = (change: GitFileChange) => {
  const before =
    change.status === "added" || change.status === "untracked"
      ? "/dev/null"
      : "a/file";
  const after = change.status === "deleted" ? "/dev/null" : "b/file";
  const hunks =
    change.diff?.hunks
      .map(
        (hunk) =>
          `@@ -${hunk.oldStart},${hunk.oldCount} +${hunk.newStart},${hunk.newCount} @@\n` +
          hunk.lines
            .map(
              (line) =>
                `${line.kind === "added" ? "+" : line.kind === "removed" ? "-" : " "}${line.text}\n`,
            )
            .join(""),
      )
      .join("") ?? "";
  return `--- ${before}\n+++ ${after}\n${hunks}`;
};

// Pierre's unified-patch parser does not decode Git-quoted names. Set real names
// after parsing so tabs, newlines and quotes in filenames cannot become headers.
export const displayDiff = (change: GitFileChange) => ({
  ...getSingularPatch(displayPatch(change)),
  name: change.path,
  prevName: change.previousPath,
});
