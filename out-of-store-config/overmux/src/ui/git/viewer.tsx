import type { GitChanges, GitFileChange } from "@overmux/git/shared";
import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent,
} from "react";
import { GitFileDiff, LineStats } from "./diff";
import { GitFileTree } from "./file-tree";
import {
  comparisonTitle,
  navigateChange,
  orderedChanges,
  orderedComparisons,
  type FileSelection,
} from "./model";
import { useDesktopLayout, useDiffTextSize } from "./mobile";
import { MobileDiffSwipe } from "./mobile-swipe";
import "./styles.css";

const clampWidth = (width: number, available: number) =>
  Math.max(120, Math.min(width, 560, available * 0.6));

const sumLineStats = (changes: GitFileChange[]) => {
  const available = changes.flatMap(({ lineStats }) =>
    lineStats ? [lineStats] : [],
  );
  if (!available.length) return null;
  return available.reduce(
    (total, stats) => ({
      added: total.added + stats.added,
      deleted: total.deleted + stats.deleted,
    }),
    { added: 0, deleted: 0 },
  );
};

export const GitViewer = ({
  data,
  onSelectionChange,
  selected,
}: {
  data: GitChanges;
  onSelectionChange: (selection: FileSelection | undefined) => void;
  selected: ReturnType<typeof orderedChanges>[number] | undefined;
}) => {
  const entries = useMemo(() => orderedChanges(data), [data]);
  const root = useRef<HTMLDivElement>(null);
  const sidebar = useRef<HTMLElement>(null);
  const separator = useRef<HTMLDivElement>(null);
  const { ref: diff, fontSize, resetFontSize } = useDiffTextSize();
  const [width, setWidth] = useState<number>();
  const [activePane, setActivePane] = useState("diff");
  const desktop = useDesktopLayout();
  const drag = useRef<{ x: number; width: number } | undefined>(undefined);
  const select = (next: FileSelection | undefined) => onSelectionChange(next);
  useEffect(() => {
    if (diff.current) diff.current.scrollTop = 0;
  }, [selected?.comparison, selected?.path]);
  useEffect(() => {
    if (!root.current) return;
    const observer = new ResizeObserver(([entry]) => {
      if (entry)
        setWidth((previous) =>
          previous === undefined
            ? undefined
            : clampWidth(previous, entry.contentRect.width),
        );
    });
    observer.observe(root.current);
    return () => observer.disconnect();
  }, []);
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.altKey || event.metaKey) return;
      const focusPane =
        event.ctrlKey &&
        event.shiftKey &&
        ["ArrowLeft", "ArrowRight"].includes(event.key);
      if (focusPane || event.key === "F6") {
        event.preventDefault();
        event.stopPropagation();
        if (event.key === "F6") {
          const panes = desktop
            ? [sidebar.current, separator.current, diff.current]
            : [diff.current];
          const current = panes.findIndex(
            (pane) =>
              pane === document.activeElement ||
              pane?.contains(document.activeElement),
          );
          panes[
            (current + (event.shiftKey ? panes.length - 1 : 1)) % panes.length
          ]?.focus();
        } else
          (event.key === "ArrowLeft" && desktop
            ? sidebar.current
            : diff.current
          )?.focus();
        return;
      }
      const treeFocused = sidebar.current?.contains(document.activeElement);
      const fileNavigation =
        !event.ctrlKey &&
        (event.key === "Tab" ||
          (treeFocused && ["ArrowUp", "ArrowDown"].includes(event.key)));
      if (fileNavigation) {
        event.preventDefault();
        event.stopPropagation();
        select(
          navigateChange(
            entries,
            selected,
            event.key === "ArrowUp" || (event.key === "Tab" && event.shiftKey)
              ? -1
              : 1,
          ),
        );
      }
      if (
        event.ctrlKey &&
        !event.shiftKey &&
        ["d", "u", "ArrowDown", "ArrowUp"].includes(event.key)
      ) {
        event.preventDefault();
        event.stopPropagation();
        const pane = diff.current;
        pane?.scrollBy({
          top:
            (pane.clientHeight / 2) *
            (["u", "ArrowUp"].includes(event.key) ? -1 : 1),
        });
      }
    };
    document.addEventListener("keydown", onKeyDown, true);
    return () => document.removeEventListener("keydown", onKeyDown, true);
  }, [desktop, entries, selected]);

  const resize = (next: number) =>
    setWidth(clampWidth(next, root.current?.clientWidth ?? window.innerWidth));
  const startResize = (event: PointerEvent<HTMLDivElement>) => {
    if (event.button !== 0) return;
    event.preventDefault();
    event.currentTarget.focus();
    event.currentTarget.setPointerCapture(event.pointerId);
    drag.current = {
      x: event.clientX,
      width: sidebar.current?.getBoundingClientRect().width ?? 280,
    };
  };
  const selectedKey = selected
    ? JSON.stringify([selected.comparison, selected.path])
    : "empty";

  return (
    <div
      className="git-viewer"
      ref={root}
      style={
        {
          "--git-sidebar-width": width ? `${width}px` : undefined,
          "--om-diff-font-size": `${fontSize}px`,
          "--om-diff-line-height": `${Math.round((fontSize * 5) / 3)}px`,
        } as CSSProperties
      }
    >
      {desktop ? (
        <>
          <aside
            aria-label="Changed files"
            className="git-sidebar"
            data-active={activePane === "sidebar"}
            onFocusCapture={() => setActivePane("sidebar")}
            onPointerDownCapture={() => setActivePane("sidebar")}
            ref={sidebar}
            tabIndex={-1}
          >
            {orderedComparisons(data.comparisons).map(
              ([comparison, changes]) => (
                <section key={comparison}>
                  <h2>
                    <span className="git-sidebar-heading-title">
                      {comparisonTitle(comparison)}{" "}
                      <span className="git-sidebar-file-count">
                        ({changes.length})
                      </span>
                    </span>
                    <span className="git-sidebar-heading-stats">
                      <LineStats lineStats={sumLineStats(changes)} />
                    </span>
                  </h2>
                  {changes.length ? (
                    <GitFileTree
                      changes={changes}
                      onSelect={(path) => select({ comparison, path })}
                      selectedPath={
                        selected?.comparison === comparison
                          ? selected.path
                          : undefined
                      }
                      title={comparisonTitle(comparison)}
                    />
                  ) : (
                    <p className="git-empty-group">No changes.</p>
                  )}
                </section>
              ),
            )}
            <p className="git-key-hint">
              Tab / ⇧Tab files · Ctrl⇧←/→ panes · F6 focus / resize
            </p>
          </aside>
          <div
            aria-label="Resize file tree"
            aria-orientation="vertical"
            aria-valuemin={120}
            aria-valuemax={560}
            aria-valuenow={Math.round(width ?? 280)}
            className="git-resizer"
            onKeyDown={(event) => {
              if (
                !["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)
              )
                return;
              event.preventDefault();
              resize(
                event.key === "Home"
                  ? 120
                  : event.key === "End"
                    ? 560
                    : (sidebar.current?.clientWidth ?? 280) +
                      (event.key === "ArrowLeft" ? -20 : 20),
              );
            }}
            onPointerDown={startResize}
            onPointerMove={(event) => {
              if (drag.current)
                resize(drag.current.width + event.clientX - drag.current.x);
            }}
            onPointerUp={() => {
              drag.current = undefined;
            }}
            onLostPointerCapture={() => {
              drag.current = undefined;
            }}
            ref={separator}
            role="separator"
            tabIndex={0}
          />
        </>
      ) : null}
      <MobileDiffSwipe
        enabled={!desktop}
        entries={entries}
        onSelectionChange={onSelectionChange}
        selected={selected}
      >
        <div
          aria-label="File diff"
          className="git-diff om-source-control-diff"
          data-active={activePane === "diff"}
          onDoubleClick={resetFontSize}
          onFocusCapture={() => setActivePane("diff")}
          onPointerDownCapture={() => {
            setActivePane("diff");
            diff.current?.focus({ preventScroll: true });
          }}
          ref={diff}
          tabIndex={0}
        >
          {selected ? (
            <GitFileDiff
              change={selected.change}
              comparison={selected.comparison}
              key={selectedKey}
            />
          ) : (
            <p role="status">No changes in these comparisons.</p>
          )}
        </div>
      </MobileDiffSwipe>
    </div>
  );
};
