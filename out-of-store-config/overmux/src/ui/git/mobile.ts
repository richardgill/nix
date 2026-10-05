import { useEffect, useRef, useState } from "react";

export const desktopLayoutQuery = "(min-width: 768px) and (pointer: fine)";
const compactQuery =
  "(max-width: 767px), (max-height: 500px) and (orientation: landscape)";

const useMediaQuery = (queryText: string) => {
  const [matches, setMatches] = useState(() => matchMedia(queryText).matches);
  useEffect(() => {
    const query = matchMedia(queryText);
    const update = () => setMatches(query.matches);
    query.addEventListener?.("change", update);
    return () => query.removeEventListener?.("change", update);
  }, [queryText]);
  return matches;
};

export const useDesktopLayout = () => useMediaQuery(desktopLayoutQuery);
export const useMobilePortrait = () =>
  useMediaQuery("(pointer: coarse) and (orientation: portrait)");
const defaultFontSize = () => (matchMedia(compactQuery).matches ? 10 : 12);
const touchDistance = (touches: TouchList) => {
  const [first, second] = [touches[0], touches[1]];
  return first && second
    ? Math.hypot(second.clientX - first.clientX, second.clientY - first.clientY)
    : 0;
};

// Use non-passive touchmove rather than pointer capture so one-finger scrolling still works.
export const useDiffTextSize = () => {
  const ref = useRef<HTMLDivElement>(null);
  const [fontSize, setFontSize] = useState(defaultFontSize);
  const size = useRef(fontSize);
  size.current = fontSize;
  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    let pinch: { distance: number; fontSize: number } | undefined;
    const start = (event: TouchEvent) => {
      pinch =
        event.touches.length === 2
          ? { distance: touchDistance(event.touches), fontSize: size.current }
          : undefined;
    };
    const move = (event: TouchEvent) => {
      if (!pinch || event.touches.length !== 2 || !pinch.distance) return;
      event.preventDefault();
      event.stopPropagation();
      setFontSize(
        Math.round(
          Math.min(
            16,
            Math.max(
              8,
              (pinch.fontSize * touchDistance(event.touches)) / pinch.distance,
            ),
          ) * 4,
        ) / 4,
      );
    };
    const end = () => {
      pinch = undefined;
    };
    const controller = new AbortController();
    element.addEventListener("touchstart", start, {
      capture: true,
      signal: controller.signal,
    });
    element.addEventListener("touchmove", move, {
      capture: true,
      passive: false,
      signal: controller.signal,
    });
    element.addEventListener("touchend", end, {
      capture: true,
      signal: controller.signal,
    });
    element.addEventListener("touchcancel", end, {
      capture: true,
      signal: controller.signal,
    });
    return () => controller.abort();
  }, []);
  return { ref, fontSize, resetFontSize: () => setFontSize(defaultFontSize()) };
};

type LockableOrientation = ScreenOrientation & {
  lock?: (orientation: "landscape") => Promise<void>;
};
let landscapeRequest = 0;
let enteredFullscreen = false;
let lockedOrientation = false;

export const releaseDiffLandscape = () => {
  landscapeRequest += 1;
  if (lockedOrientation) screen.orientation?.unlock();
  lockedOrientation = false;
  if (enteredFullscreen && document.fullscreenElement)
    void document.exitFullscreen().catch(() => {});
  enteredFullscreen = false;
};

// Called directly by the open command while the browser still has user activation.
export const requestDiffLandscape = async () => {
  const orientation = screen.orientation as LockableOrientation | undefined;
  if (!matchMedia("(pointer: coarse)").matches || !orientation?.lock)
    return false;
  const request = ++landscapeRequest;
  const needsFullscreen =
    !document.fullscreenElement &&
    Boolean(document.documentElement.requestFullscreen);
  try {
    if (needsFullscreen) await document.documentElement.requestFullscreen();
    if (request !== landscapeRequest) {
      if (needsFullscreen && document.fullscreenElement)
        await document.exitFullscreen();
      return false;
    }
    enteredFullscreen = needsFullscreen;
    await orientation.lock("landscape");
    lockedOrientation = true;
    if (request !== landscapeRequest) {
      releaseDiffLandscape();
      return false;
    }
    return true;
  } catch {
    releaseDiffLandscape();
    return false;
  }
};
