// Read-only adaptation of https://github.com/richardgill/overmux/pull/17.
import type { GitFileChange } from "@overmux/git/shared";
import type { FileTreeRowDecorationContext } from "@pierre/trees";
import {
  FileTree,
  useFileTree,
  useFileTreeSelector,
} from "@pierre/trees/react";
import { useCallback, useEffect, useId, useMemo, useRef } from "react";

const itemHeight = 28;
const treeCSS = `
[data-file-tree-virtualized-scroll="true"] { overflow-y: hidden; scrollbar-gutter: auto; }
[data-type="item"]:has([data-item-section="decoration"] > span) > [data-item-section="content"] { display: none; }
[data-item-section="decoration"] { min-width: 0; justify-content: flex-start; overflow: hidden; text-align: start; }
[data-item-section="decoration"] > span { display: flex; gap: .375rem; min-width: 0; width: 100%; }
[data-item-section="decoration"] > span > span:first-child { flex: 1 1 0; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
[data-item-section="decoration"] > span > span:not(:first-child) { flex: none; white-space: nowrap; }
[data-type="item"][data-item-selected="true"]::before { content: ""; position: absolute; inset: 0; outline: 1px solid #7aa2f7; outline-offset: -1px; pointer-events: none; }
[data-item-contains-git-change="true"]:not([data-item-git-status]) > [data-item-section="git"] { display: none; }
`;

type Props = {
  changes: GitFileChange[];
  onSelect: (path: string) => void;
  selectedPath?: string;
  title: string;
};

const FileTreeModel = ({ changes, onSelect, selectedPath, title }: Props) => {
  const id = `git-tree-${useId().replaceAll(":", "")}`;
  const byPath = useMemo(
    () => new Map(changes.map((change) => [change.path, change])),
    [changes],
  );
  const state = useRef({ byPath, onSelect });
  state.current = { byPath, onSelect };
  const syncing = useRef(false);
  const onSelectionChange = useCallback((paths: readonly string[]) => {
    const path = paths.at(-1);
    if (!syncing.current && path && state.current.byPath.has(path))
      state.current.onSelect(path);
  }, []);
  const renderRowDecoration = useCallback(
    ({ item }: FileTreeRowDecorationContext) => {
      const change = state.current.byPath.get(item.path);
      if (!change) return null;
      const name = `${change.status === "conflicted" ? "⚠ " : ""}${change.path.split("/").at(-1) ?? change.path}`;
      const parts = change.lineStats
        ? [
            { text: name },
            { color: "#3fb950", text: `+${change.lineStats.added}` },
            { color: "#f85149", text: `-${change.lineStats.deleted}` },
          ]
        : [{ text: name }, { text: change.binary ? "binary" : change.status }];
      return {
        parts,
        text: parts.map(({ text }) => text).join(" "),
        title: item.path,
      };
    },
    [],
  );
  const { model } = useFileTree({
    flattenEmptyDirectories: true,
    gitStatus: changes.flatMap(({ path, status }) =>
      status === "conflicted" ? [] : [{ path, status }],
    ),
    id,
    initialExpansion: "open",
    initialSelectedPaths: selectedPath ? [selectedPath] : [],
    itemHeight,
    onSelectionChange,
    paths: changes.map(({ path }) => path),
    renderRowDecoration,
    unsafeCSS: treeCSS,
  });
  const visibleRowCount = useFileTreeSelector(model, (tree) =>
    tree.getVisibleCount(),
  );

  useEffect(() => {
    const paths = model.getSelectedPaths();
    if (paths.length === (selectedPath ? 1 : 0) && paths[0] === selectedPath)
      return;
    syncing.current = true;
    paths.forEach((path) => model.getItem(path)?.deselect());
    if (selectedPath) model.getItem(selectedPath)?.select();
    syncing.current = false;
  }, [model, selectedPath]);

  useEffect(() => {
    const shadow = document.getElementById(id)?.shadowRoot;
    if (!shadow) return;
    const updateRows = () =>
      shadow
        .querySelectorAll<HTMLElement>("[data-item-path]")
        .forEach((row) => {
          const path = row.dataset.itemPath;
          if (path && byPath.has(path)) row.setAttribute("aria-label", path);
        });
    updateRows();
    const observer = new MutationObserver(updateRows);
    observer.observe(shadow, { childList: true, subtree: true });
    const rows = shadow.querySelectorAll<HTMLElement>("[data-item-path]");
    [...rows]
      .find((row) => row.dataset.itemPath === selectedPath)
      ?.scrollIntoView?.({ block: "nearest" });
    return () => observer.disconnect();
  }, [byPath, id, selectedPath, visibleRowCount]);

  return (
    <FileTree
      aria-label={`${title} files`}
      className="git-file-tree"
      id={id}
      model={model}
      style={{ height: visibleRowCount * itemHeight }}
    />
  );
};

export const GitFileTree = (props: Props) => (
  <FileTreeModel
    {...props}
    key={JSON.stringify(
      props.changes.map(({ path, status, lineStats, binary }) => [
        path,
        status,
        lineStats,
        binary,
      ]),
    )}
  />
);
