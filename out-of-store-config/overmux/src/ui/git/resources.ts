import { skipToken } from "overmux/client";
import { useEffect, useState } from "react";

import { useResource } from "../utils/overmux-hooks";
import { comparisonInput } from "./model";

export const gitPreloadDelayMs = 200;

export const useActiveGitResources = (cwd: string | undefined) => {
  const repository = useResource({
    id: "gitRepository",
    input: cwd ? { cwd } : skipToken,
  });
  const repoRoot =
    repository?.status === "success" ? repository.data.repoRoot : undefined;
  const [subscribedRoot, setSubscribedRoot] = useState<string>();

  // Resolve cwd cheaply first; brief pane changes don't churn expensive hunk watches.
  // A same-repository cwd change retains both watches if discovery settles in time.
  useEffect(() => {
    const timeout = setTimeout(
      () => setSubscribedRoot(repoRoot),
      gitPreloadDelayMs,
    );
    return () => clearTimeout(timeout);
  }, [cwd, repoRoot]);

  const activeRoot = cwd ? subscribedRoot : undefined;
  const uncommitted = useResource({
    id: "gitChanges",
    input: activeRoot
      ? {
          comparisons: comparisonInput("uncommitted"),
          detailLevel: "hunks",
          repoRoot: activeRoot,
        }
      : skipToken,
  });
  const workingTree = useResource({
    id: "gitChanges",
    input: activeRoot
      ? {
          comparisons: comparisonInput("workingTree"),
          detailLevel: "hunks",
          repoRoot: activeRoot,
        }
      : skipToken,
  });

  // Never expose the previous pane's hunks while discovery/debounce is pending.
  const current = Boolean(repoRoot) && repoRoot === activeRoot;
  return {
    repository,
    uncommitted: current ? uncommitted : undefined,
    workingTree: current ? workingTree : undefined,
  };
};

export type ActiveGitResources = ReturnType<typeof useActiveGitResources>;
