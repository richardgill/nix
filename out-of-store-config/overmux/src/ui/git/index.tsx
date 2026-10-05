import { useParams, useRouter } from "@tanstack/react-router";
import { useEffect, useMemo, useState } from "react";
import { z } from "zod";

import { FullscreenDialog } from "../components/fullscreen-dialog";
import { DialogTitle } from "../shadcn/dialog";
import { workspaceNavigationHash } from "../utils/router-history";
import { useRouteState } from "../utils/use-route-state";
import {
  displayBranch,
  navigateChange,
  orderedChanges,
  resolveSelection,
  type FileSelection,
} from "./model";
import {
  releaseDiffLandscape,
  requestDiffLandscape,
  useMobilePortrait,
} from "./mobile";
import { GitViewer } from "./viewer";
import { useActiveGitResources, type ActiveGitResources } from "./resources";

const gitChangesOverlaySchema = z
  .object({ comparison: z.enum(["workingTree", "uncommitted"]) })
  .strict();

export type GitChangesOverlay = z.infer<typeof gitChangesOverlaySchema>;

export const gitChangesSearchSchema = z.object({
  gitChanges: gitChangesOverlaySchema.optional().catch(undefined),
});

export const gitChangesPath = (comparison: GitChangesOverlay["comparison"]) =>
  `/git/${comparison === "workingTree" ? "base" : "changes"}`;

const gitChangesVisibleLocation = (selection: GitChangesOverlay | undefined) =>
  selection ? { to: gitChangesPath(selection.comparison) } : undefined;

const titleFor = (comparison: GitChangesOverlay["comparison"]) =>
  comparison === "workingTree" ? "Changes vs origin/main" : "Local changes";

const rememberedSelections = new Map<string, FileSelection>();

export const MobilePortraitGate = () => {
  const [rotateManually, setRotateManually] = useState(false);
  const requestLandscape = async () => {
    if (!(await requestDiffLandscape())) setRotateManually(true);
  };

  return (
    <div className="flex flex-1 items-center justify-center p-6">
      <DialogTitle className="sr-only">Git changes</DialogTitle>
      <button
        className="min-h-32 max-w-72 rounded-lg bg-accent px-8 py-6 text-lg font-semibold text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        onClick={() => void requestLandscape()}
        type="button"
      >
        {rotateManually
          ? "Rotate your device to landscape"
          : "Switch to landscape"}
      </button>
    </div>
  );
};

export const GitChangesContent = ({
  branch,
  data,
  mode,
  repoPath,
  title,
}: {
  branch?: string;
  data: Parameters<typeof GitViewer>[0]["data"];
  mode: GitChangesOverlay["comparison"];
  repoPath?: string;
  title: string;
}) => {
  const memoryKey = JSON.stringify([data.repoRoot, mode]);
  const [selection, setSelection] = useState(() =>
    rememberedSelections.get(memoryKey),
  );
  const entries = useMemo(() => orderedChanges(data), [data]);
  const selected = resolveSelection(entries, selection);
  useEffect(() => {
    if (selected)
      rememberedSelections.set(memoryKey, {
        comparison: selected.comparison,
        path: selected.path,
      });
  }, [memoryKey, selected?.comparison, selected?.path]);
  const select = (next: FileSelection | undefined) => {
    if (!next) return;
    const value = { comparison: next.comparison, path: next.path };
    setSelection(value);
    rememberedSelections.set(memoryKey, value);
  };
  const navigate = (direction: 1 | -1) =>
    select(navigateChange(entries, selected, direction));
  const disabled = entries.length < 2;

  return (
    <>
      <header className="flex shrink-0 items-center gap-1 border-b px-4 py-3 pr-12 [@media(min-width:768px)_and_(pointer:fine)]:pr-32">
        <DialogTitle asChild>
          <h1 className="shrink-0 whitespace-nowrap font-semibold">{title}</h1>
        </DialogTitle>
        {repoPath ? (
          <p className="min-w-0 truncate text-sm text-foreground/60">
            <span aria-hidden="true"> · </span>
            {repoPath}
            {branch ? ` · ${branch}` : ""}
          </p>
        ) : null}
        <div className="git-mobile-file-navigation">
          <button
            aria-label="Previous changed file"
            disabled={disabled}
            onClick={() => navigate(-1)}
            type="button"
          >
            ↑
          </button>
          <button
            aria-label="Next changed file"
            disabled={disabled}
            onClick={() => navigate(1)}
            type="button"
          >
            ↓
          </button>
        </div>
      </header>
      <section className="flex min-h-0 flex-1 flex-col text-foreground/70 [&>p]:p-4">
        <GitViewer data={data} onSelectionChange={select} selected={selected} />
      </section>
    </>
  );
};

const GitChangesDialog = ({
  cwd,
  resources,
  onCloseAutoFocus,
  selection,
  setSelection,
}: {
  cwd?: string;
  onCloseAutoFocus?: () => void;
  selection: GitChangesOverlay;
  resources: ActiveGitResources;
  setSelection: (selection: undefined) => Promise<void>;
}) => {
  const mobilePortrait = useMobilePortrait();
  const { repository } = resources;
  const changes = resources[selection.comparison];
  useEffect(() => releaseDiffLandscape, []);
  const close = () => void setSelection(undefined);
  const repoPath = repository?.data?.displayPath ?? cwd;
  const branch =
    repository?.data && changes?.data
      ? displayBranch({
          branch: changes.data.branch,
          isWorktree: repository.data.isWorktree,
          repoRoot: repository.data.repoRoot,
        })
      : undefined;
  const content = !cwd ? (
    <p>No active tmux pane.</p>
  ) : repository?.status === "pending" ? (
    <p>Finding git repository…</p>
  ) : repository?.status === "error" ? (
    <p role="alert">
      {repository.error.message}{" "}
      <button onClick={repository.refetch} type="button">
        Retry
      </button>
    </p>
  ) : changes?.status === "pending" ? (
    <p>Loading git changes…</p>
  ) : changes?.status === "error" ? (
    <p role="alert">
      {changes.error.message}{" "}
      <button onClick={changes.refetch} type="button">
        Retry
      </button>
    </p>
  ) : changes?.data ? (
    <GitChangesContent
      branch={branch}
      data={changes.data}
      key={JSON.stringify([changes.data.repoRoot, selection.comparison])}
      mode={selection.comparison}
      repoPath={repoPath}
      title={titleFor(selection.comparison)}
    />
  ) : (
    <p role="status">Loading git changes…</p>
  );

  return (
    <FullscreenDialog
      hideCloseButton={mobilePortrait}
      onClose={close}
      onCloseAutoFocus={onCloseAutoFocus}
      open
    >
      <main className="flex min-h-0 flex-1 flex-col bg-background text-foreground">
        {mobilePortrait ? (
          <MobilePortraitGate />
        ) : changes?.data ? (
          content
        ) : (
          <>
            <header className="flex shrink-0 items-center gap-1 border-b px-4 py-3 pr-12 [@media(min-width:768px)_and_(pointer:fine)]:pr-32">
              <DialogTitle asChild>
                <h1 className="shrink-0 whitespace-nowrap font-semibold">
                  {titleFor(selection.comparison)}
                </h1>
              </DialogTitle>
              {repoPath ? (
                <p
                  className="min-w-0 truncate text-sm text-foreground/60"
                  title={repository?.data?.repoRoot ?? cwd}
                >
                  <span aria-hidden="true"> · </span>
                  {repoPath}
                  {branch ? ` · ${branch}` : ""}
                </p>
              ) : null}
            </header>
            <section className="flex min-h-0 flex-1 flex-col text-foreground/70 [&>p]:p-4">
              {content}
            </section>
          </>
        )}
      </main>
    </FullscreenDialog>
  );
};

export const GitChangesRoute = ({
  cwd,
  onCloseAutoFocus,
}: {
  cwd?: string;
  onCloseAutoFocus?: () => void;
}) => {
  // This route stays mounted with the terminal and is the sole owner of both watches.
  const resources = useActiveGitResources(cwd);
  // Internal tmux search state keeps the terminal mounted behind this masked modal.
  const [selection, setSelection] = useRouteState({
    getVisibleLocation: gitChangesVisibleLocation,
    historyMode: "push",
    routeId: "/tmux",
    searchParam: "gitChanges",
  });

  return selection ? (
    <GitChangesDialog
      cwd={cwd}
      resources={resources}
      onCloseAutoFocus={onCloseAutoFocus}
      selection={selection}
      setSelection={setSelection}
    />
  ) : null;
};

export const GitChangesRedirectRoute = () => {
  const router = useRouter();
  const { mode } = useParams({ strict: false });
  const comparison = mode === "base" ? "workingTree" : "uncommitted";

  useEffect(() => {
    void router.navigate({
      mask: { to: gitChangesPath(comparison) },
      replace: true,
      search: { gitChanges: { comparison } },
      to: "/tmux",
    });
  }, [comparison, router]);
  return null;
};

export const openGitChanges = (
  router: ReturnType<typeof useRouter>,
  comparison: GitChangesOverlay["comparison"],
) => {
  return router.navigate({
    hash: workspaceNavigationHash(router, { masked: true }),
    mask: { to: gitChangesPath(comparison) },
    search: (search) => ({ ...search, gitChanges: { comparison } }),
    to: ".",
  });
};
