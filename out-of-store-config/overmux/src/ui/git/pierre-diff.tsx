// Adapted from https://github.com/richardgill/overmux/pull/17.
import {
  FileDiff as FileDiffInstance,
  parseDiffFromFile,
  type FileDiffOptions,
  type FileDiffMetadata,
  type HunkData,
} from "@pierre/diffs";
import { FileDiff } from "@pierre/diffs/react";
import {
  createElement,
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type RefObject,
} from "react";

const useIsomorphicLayoutEffect =
  typeof window === "undefined" ? useEffect : useLayoutEffect;
const EXPANSION_LINE_COUNT = 20;

export type GitDiffStyle = "split" | "unified";
export type GitDiffOptions = Omit<
  FileDiffOptions<undefined>,
  "diffStyle" | "disableFileHeader"
>;

export type PierrePatchDiffProps = {
  className?: string;
  diffStyle?: GitDiffStyle;
  options?: GitDiffOptions;
  fileDiff: FileDiffMetadata;
};

export type PierreFileDiffProps = {
  cacheKey: string;
  className?: string;
  diffStyle?: GitDiffStyle;
  newContent: string | null;
  oldContent: string | null;
  options?: GitDiffOptions;
  path: string;
  previousPath?: string;
  expandUnchanged?: boolean;
};

const selectionPoint = ({
  event,
  root,
}: {
  event: PointerEvent;
  root: ShadowRoot;
}) => {
  const position = document.caretPositionFromPoint?.(
    event.clientX,
    event.clientY,
    {
      shadowRoots: [root],
    },
  );
  if (position) {
    return { node: position.offsetNode, offset: position.offset };
  }
  const range = document.caretRangeFromPoint?.(event.clientX, event.clientY);
  if (range) {
    return { node: range.startContainer, offset: range.startOffset };
  }
};

const setSelection = ({
  event,
  extend,
  root,
}: {
  event: PointerEvent;
  extend: boolean;
  root: ShadowRoot;
}) => {
  const point = selectionPoint({ event, root });
  if (!point) {
    return;
  }
  const selection = document.getSelection();
  if (!selection) {
    return;
  }
  if (extend) {
    selection.extend(point.node, point.offset);
    return;
  }
  const range = document.createRange();
  range.setStart(point.node, point.offset);
  range.collapse();
  selection.removeAllRanges();
  selection.addRange(range);
};

const isDiffText = (event: PointerEvent) =>
  event
    .composedPath()
    .some(
      (element) =>
        element instanceof HTMLElement && element.hasAttribute("data-line"),
    );

const useNativeTextSelection = (
  container: RefObject<HTMLDivElement | null>,
) => {
  useEffect(() => {
    const diffContainer =
      container.current?.querySelector("diffs-container") ??
      container.current?.querySelector<HTMLElement>("[data-om-pierre-diff]");
    const root = diffContainer?.shadowRoot;
    if (!(diffContainer instanceof HTMLElement) || !root) {
      return;
    }
    let selecting = false;
    const onPointerDown = (event: PointerEvent) => {
      if (
        event.pointerType !== "mouse" ||
        event.button !== 0 ||
        !isDiffText(event)
      ) {
        return;
      }
      event.preventDefault();
      event.stopImmediatePropagation();
      selecting = true;
      setSelection({ event, extend: false, root });
    };
    const onPointerMove = (event: PointerEvent) => {
      if (!selecting) {
        return;
      }
      event.preventDefault();
      setSelection({ event, extend: true, root });
    };
    const onPointerUp = (event: PointerEvent) => {
      if (!selecting) {
        return;
      }
      event.preventDefault();
      selecting = false;
    };
    diffContainer.addEventListener("pointerdown", onPointerDown, true);
    document.addEventListener("pointermove", onPointerMove, true);
    document.addEventListener("pointerup", onPointerUp, true);
    return () => {
      diffContainer.removeEventListener("pointerdown", onPointerDown, true);
      document.removeEventListener("pointermove", onPointerMove, true);
      document.removeEventListener("pointerup", onPointerUp, true);
    };
  }, [container]);
};

const afterRender = (action: () => void) =>
  requestAnimationFrame(() => requestAnimationFrame(action));

const preserveSeparatorPosition = (
  separator: HTMLElement,
  action: () => void,
) => {
  const pane = separator.closest<HTMLElement>(".om-source-control-diff");
  const file = separator.closest<HTMLElement>("[data-om-git-file]");
  const identity = separator.dataset.omGitSeparator;
  const top = separator.getBoundingClientRect().top;
  action();
  afterRender(() => {
    const next = file?.querySelector<HTMLElement>(
      `[data-om-git-separator="${identity}"]`,
    );
    if (pane && next) {
      pane.scrollTop += next.getBoundingClientRect().top - top;
    }
  });
};

const preserveScrollTop = (element: HTMLElement, action: () => void) => {
  const pane = element.closest<HTMLElement>(".om-source-control-diff");
  const scrollTop = pane?.scrollTop;
  action();
  afterRender(() => {
    if (pane && scrollTop !== undefined) {
      pane.scrollTop = scrollTop;
    }
  });
};

type ExpansionIcon = "fold-up" | "unfold";

// https://primer.style/octicons/fold-up-16 and https://primer.style/octicons/unfold-16
const expansionIconPaths: Record<ExpansionIcon, string> = {
  "fold-up":
    "M7.823 1.677 4.927 4.573A.25.25 0 0 0 5.104 5H7.25v3.236a.75.75 0 1 0 1.5 0V5h2.146a.25.25 0 0 0 .177-.427L8.177 1.677a.25.25 0 0 0-.354 0ZM13.75 11a.75.75 0 0 0 0 1.5h.5a.75.75 0 0 0 0-1.5h-.5Zm-3.75.75a.75.75 0 0 1 .75-.75h.5a.75.75 0 0 1 0 1.5h-.5a.75.75 0 0 1-.75-.75ZM7.75 11a.75.75 0 0 0 0 1.5h.5a.75.75 0 0 0 0-1.5h-.5ZM4 11.75a.75.75 0 0 1 .75-.75h.5a.75.75 0 0 1 0 1.5h-.5a.75.75 0 0 1-.75-.75ZM1.75 11a.75.75 0 0 0 0 1.5h.5a.75.75 0 0 0 0-1.5h-.5Z",
  unfold:
    "m8.177.677 2.896 2.896a.25.25 0 0 1-.177.427H8.75v1.25a.75.75 0 0 1-1.5 0V4H5.104a.25.25 0 0 1-.177-.427L7.823.677a.25.25 0 0 1 .354 0ZM7.25 10.75a.75.75 0 0 1 1.5 0V12h2.146a.25.25 0 0 1 .177.427l-2.896 2.896a.25.25 0 0 1-.354 0l-2.896-2.896A.25.25 0 0 1 5.104 12H7.25v-1.25Zm-5-2a.75.75 0 0 0 0-1.5h-.5a.75.75 0 0 0 0 1.5h.5ZM6 8a.75.75 0 0 1-.75.75h-.5a.75.75 0 0 1 0-1.5h.5A.75.75 0 0 1 6 8Zm2.25.75a.75.75 0 0 0 0-1.5h-.5a.75.75 0 0 0 0 1.5h.5ZM12 8a.75.75 0 0 1-.75.75h-.5a.75.75 0 0 1 0-1.5h.5A.75.75 0 0 1 12 8Zm2.25.75a.75.75 0 0 0 0-1.5h-.5a.75.75 0 0 0 0 1.5h.5Z",
};

const createButton = (
  label: string,
  icon: ExpansionIcon,
  action: () => void,
) => {
  const button = document.createElement("button");
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
  button.className = "om-git-diff-expand-button";
  button.type = "button";
  button.setAttribute("aria-label", label);
  button.title = label;
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("height", "16");
  svg.setAttribute("viewBox", "0 0 16 16");
  svg.setAttribute("width", "16");
  path.setAttribute("d", expansionIconPaths[icon]);
  svg.append(path);
  button.append(svg);
  button.addEventListener("click", (event) => {
    event.stopPropagation();
    action();
  });
  return button;
};

const createHunkSeparator = ({
  hunk,
  instance,
  expandWholeFile,
}: {
  hunk: HunkData;
  instance: FileDiffInstance<undefined>;
  expandWholeFile: () => void;
}) => {
  if (hunk.type === "deletions") {
    return null;
  }
  const separator = document.createElement("div");
  separator.className = "om-git-diff-expander";
  separator.dataset.omGitSeparator = `${hunk.hunkIndex}-${hunk.type}`;
  separator.setAttribute("role", "group");
  separator.setAttribute(
    "aria-label",
    `${hunk.lines} omitted unchanged ${hunk.lines === 1 ? "line" : "lines"}`,
  );
  const direction = hunk.expandable?.down
    ? "down"
    : hunk.expandable?.up
      ? "up"
      : undefined;
  if (direction) {
    separator.append(
      createButton("Expand upward", "fold-up", () =>
        preserveSeparatorPosition(separator, () =>
          instance.expandHunk(hunk.hunkIndex, direction, EXPANSION_LINE_COUNT),
        ),
      ),
    );
  }
  separator.append(
    createButton("Expand whole file", "unfold", () =>
      preserveScrollTop(separator, expandWholeFile),
    ),
  );
  const label = document.createElement("span");
  label.className = "om-git-diff-expander-label";
  label.textContent = `${hunk.lines} unchanged ${hunk.lines === 1 ? "line" : "lines"}`;
  separator.append(label);
  return separator;
};

export const PierrePatchDiff = ({
  className,
  diffStyle = "unified",
  options,
  fileDiff,
}: PierrePatchDiffProps) => {
  const container = useRef<HTMLDivElement>(null);
  useNativeTextSelection(container);
  return (
    <div ref={container} style={{ display: "contents" }}>
      <FileDiff
        className={className}
        disableWorkerPool
        options={{ ...options, diffStyle, disableFileHeader: true }}
        fileDiff={fileDiff}
      />
    </div>
  );
};

export const PierreFileDiff = ({
  cacheKey,
  className,
  diffStyle = "unified",
  newContent,
  oldContent,
  options,
  path,
  previousPath,
  expandUnchanged = false,
}: PierreFileDiffProps) => {
  const container = useRef<HTMLDivElement>(null);
  const diffContainer = useRef<HTMLElement>(null);
  const instance = useRef<FileDiffInstance<undefined>>(null);
  const sourceVersion = useMemo(
    () => Symbol(),
    [cacheKey, newContent, oldContent, path, previousPath],
  );
  const fileDiff = useMemo(
    () =>
      parseDiffFromFile(
        oldContent === null
          ? null
          : {
              cacheKey: `${cacheKey}:old`,
              contents: oldContent,
              name: previousPath ?? path,
            },
        newContent === null
          ? null
          : {
              cacheKey: `${cacheKey}:new`,
              contents: newContent,
              name: path,
            },
      ),
    [cacheKey, newContent, oldContent, path, previousPath],
  );
  const [expandedVersion, setExpandedVersion] = useState<symbol>();
  const expanded = expandUnchanged || expandedVersion === sourceVersion;
  const expandWholeFile = useCallback(
    () => setExpandedVersion(sourceVersion),
    [sourceVersion],
  );
  const renderSeparator = useCallback(
    (hunk: HunkData, diffInstance: FileDiffInstance<undefined>) =>
      createHunkSeparator({ hunk, instance: diffInstance, expandWholeFile }),
    [expandWholeFile],
  );
  const pierreOptions = useMemo<FileDiffOptions<undefined>>(
    () => ({
      ...options,
      diffStyle,
      expansionLineCount: EXPANSION_LINE_COUNT,
      disableFileHeader: true,
      expandUnchanged: expanded,
      hunkSeparators: renderSeparator,
    }),
    [diffStyle, expanded, options, renderSeparator],
  );
  useNativeTextSelection(container);
  // Pierre's React FileDiff manages its container, which disables function-based hunk separators.
  // https://github.com/pierrecomputer/pierre/issues/440
  useIsomorphicLayoutEffect(() => {
    if (!diffContainer.current) {
      return;
    }
    const next = new FileDiffInstance<undefined>(pierreOptions);
    instance.current = next;
    next.hydrate({ fileContainer: diffContainer.current, fileDiff });
    return () => {
      next.cleanUp();
      if (instance.current === next) {
        instance.current = null;
      }
    };
  }, [cacheKey, fileDiff]);
  useEffect(() => {
    instance.current?.setOptions(pierreOptions);
    instance.current?.render({ fileDiff, forceRender: true });
  }, [fileDiff, pierreOptions]);
  return (
    <div ref={container} style={{ display: "contents" }}>
      {createElement("diffs-container", {
        className,
        "data-om-pierre-diff": "",
        key: cacheKey,
        ref: diffContainer,
      })}
    </div>
  );
};
