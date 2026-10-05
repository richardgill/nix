import { skipToken } from "overmux/client";
import { useMemo, useState } from "react";
import type { GitFileChange } from "@overmux/git/shared";
import { useResource } from "../utils/overmux-hooks";
import { comparisonTitle, displayDiff } from "./model";
import {
  PierreFileDiff,
  PierrePatchDiff,
  type GitDiffStyle,
} from "./pierre-diff";
import { diffOptions } from "./theme";

export const LineStats = ({
  lineStats,
}: {
  lineStats: GitFileChange["lineStats"];
}) =>
  lineStats ? (
    <span
      className="git-line-stats"
      aria-label={`${lineStats.added} additions, ${lineStats.deleted} deletions`}
    >
      <span>+{lineStats.added}</span>
      <span>−{lineStats.deleted}</span>
    </span>
  ) : null;

const changeStatusLabels: Partial<Record<GitFileChange["status"], string>> = {
  added: "Added",
  deleted: "Deleted",
  renamed: "Renamed",
  untracked: "Untracked",
  conflicted: "Conflict",
};

const changeStatusLabel = (status: GitFileChange["status"]) =>
  changeStatusLabels[status];

const localComparisonLabel = (comparison: string) =>
  comparison === "staged" || comparison === "unstaged"
    ? comparisonTitle(comparison)
    : undefined;

export const GitFileDiff = ({
  change,
  comparison,
  diffStyle = "split",
}: {
  change: GitFileChange;
  comparison: string;
  diffStyle?: GitDiffStyle;
}) => {
  const [expansion, setExpansion] = useState<"context" | "whole">();
  const full = useResource({
    id: "gitDiff",
    input: expansion && !change.binary ? change.diffParams : skipToken,
  });
  const fileDiff = useMemo(
    () => (change.diff?.hunks.length ? displayDiff(change) : undefined),
    [change],
  );
  const contents = full?.data;
  const noTextChanges = !change.diff?.hunks.length;
  const binary = contents?.binary ?? change.binary;
  const comparisonLabel = localComparisonLabel(comparison);
  const statusLabel = changeStatusLabel(change.status);
  const content = binary ? (
    <p role="status">Binary file. Text preview is unavailable.</p>
  ) : contents?.oldContent === null && contents.newContent === null ? (
    <p role="status">File is no longer present in this comparison.</p>
  ) : contents ? (
    contents.oldContent === contents.newContent &&
    (expansion !== "whole" || !contents.newContent) ? (
      <p role="status">No textual changes.</p>
    ) : (
      <PierreFileDiff
        cacheKey={JSON.stringify([comparison, change.diffParams, contents])}
        className="git-diff-patch"
        diffStyle={diffStyle}
        expandUnchanged={expansion === "whole"}
        newContent={contents.newContent}
        oldContent={contents.oldContent}
        options={diffOptions}
        path={change.path}
        previousPath={change.previousPath}
      />
    )
  ) : noTextChanges ? (
    <p role="status">
      No textual changes. The file may have been renamed, be empty, or have
      changed mode.
    </p>
  ) : fileDiff ? (
    <PierrePatchDiff
      className="git-diff-patch"
      diffStyle={diffStyle}
      options={diffOptions}
      fileDiff={fileDiff}
    />
  ) : null;

  return (
    <article data-om-git-file>
      <header className="git-diff-header">
        <div
          className="git-diff-filename"
          title={
            change.previousPath
              ? `${change.previousPath} → ${change.path}`
              : change.path
          }
        >
          <h2>
            {change.previousPath ? `${change.previousPath} → ` : ""}
            {change.path}
          </h2>
        </div>
        {comparisonLabel && (
          <span className="git-comparison-label">{comparisonLabel}</span>
        )}
        {statusLabel && (
          <span className="git-change-status">{statusLabel}</span>
        )}
        {binary && <span className="git-binary-label">Binary</span>}
        <LineStats lineStats={change.lineStats} />
        {!binary && (
          <div className="git-context-actions">
            <button
              aria-label="Expand context"
              disabled={expansion === "context" && full?.status === "pending"}
              onClick={() => setExpansion("context")}
              title="Expand context"
              type="button"
            >
              Context
            </button>
            <button
              aria-label="Whole file"
              disabled={expansion === "whole" && full?.status === "pending"}
              onClick={() => setExpansion("whole")}
              title="Whole file"
              type="button"
            >
              Full
            </button>
          </div>
        )}
      </header>
      {change.status === "conflicted" && (
        <p role="status">
          Unresolved conflict. Showing the available working-file changes.
        </p>
      )}
      {full?.status === "pending" && (
        <p role="status">Loading full file contents…</p>
      )}
      {full?.status === "error" && (
        <p role="alert">
          Cannot load full contents: {full.error.message}{" "}
          <button onClick={full.refetch} type="button">
            Retry
          </button>
        </p>
      )}
      {content}
    </article>
  );
};
