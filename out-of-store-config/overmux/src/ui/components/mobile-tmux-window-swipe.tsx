// Presents the live terminal while mobile swipes select adjacent confirmed tmux windows.
// It owns gesture capture and its fixed visual schedule, never terminal navigation state.
import { useEffect, useRef, useState, type PointerEvent, type ReactNode } from "react";

import { xtermTheme } from "../css/xterm-theme";

const directionLockPixels = 8;
const animationDuration = 45;
const blankDuration = 100;

type Drag = {
  pointerId: number;
  startX: number;
  startY: number;
  locked: boolean;
};

type MobileTmuxWindowSwipeProps = {
  activeWindowId: string | null;
  children: ReactNode;
  onSelectWindow: (windowId: string) => void;
  windowIds: readonly string[];
};

const isMobile = () => window.matchMedia("(max-width: 767px)").matches;
const prefersReducedMotion = () =>
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const isInteractiveTarget = (target: EventTarget | null) =>
  target instanceof Element &&
  Boolean(
    target.closest(
      "a, button, input:not(.xterm-helper-textarea), textarea:not(.xterm-helper-textarea), select, [contenteditable]:not([contenteditable='false'])",
    ),
  );

export const MobileTmuxWindowSwipe = ({
  activeWindowId,
  children,
  onSelectWindow,
  windowIds,
}: MobileTmuxWindowSwipeProps) => {
  const wrapperRef = useRef<HTMLDivElement>(null);
  const drag = useRef<Drag>();
  const animationTimer = useRef<number>();
  const animationFrame = useRef<number>();
  const blankTimer = useRef<number>();
  const [blanked, setBlanked] = useState(false);
  const [offset, setOffset] = useState(0);
  const [animating, setAnimating] = useState(false);
  const [transitioning, setTransitioning] = useState(false);

  const clearAnimation = () => {
    if (animationTimer.current !== undefined) {
      window.clearTimeout(animationTimer.current);
    }
    if (animationFrame.current !== undefined) {
      cancelAnimationFrame(animationFrame.current);
    }
    if (blankTimer.current !== undefined) {
      window.clearTimeout(blankTimer.current);
    }
    animationTimer.current = undefined;
    animationFrame.current = undefined;
    blankTimer.current = undefined;
  };

  useEffect(() => clearAnimation, []);

  const cancelDrag = (pointerId?: number) => {
    const current = drag.current;
    if (!current || (pointerId !== undefined && current.pointerId !== pointerId)) {
      return;
    }
    // Clear first so release's lostpointercapture cannot cancel a completed swipe.
    drag.current = undefined;
    const wrapper = wrapperRef.current;
    if (current.locked && wrapper?.hasPointerCapture(current.pointerId)) {
      wrapper.releasePointerCapture(current.pointerId);
    }
    setOffset(0);
  };

  const animateSelection = (direction: number) => {
    if (prefersReducedMotion()) return;
    const travel = wrapperRef.current?.clientWidth ?? 0;
    if (!travel) return;
    setAnimating(true);
    setTransitioning(true);
    setOffset(direction * travel);
    animationTimer.current = window.setTimeout(() => {
      setBlanked(true);
      blankTimer.current = window.setTimeout(() => {
        blankTimer.current = undefined;
        setBlanked(false);
      }, blankDuration);
      setTransitioning(false);
      setOffset(-direction * travel);
      // Let the reverse-side position paint before starting the incoming transition.
      animationFrame.current = requestAnimationFrame(() => {
        animationFrame.current = requestAnimationFrame(() => {
          setTransitioning(true);
          setOffset(0);
          animationTimer.current = window.setTimeout(() => {
            animationTimer.current = undefined;
            setAnimating(false);
            setTransitioning(false);
          }, animationDuration);
        });
      });
    }, animationDuration);
  };

  const onPointerDown = (event: PointerEvent<HTMLDivElement>) => {
    if (!isMobile() || animating || blanked || isInteractiveTarget(event.target) || windowIds.length < 2) {
      return;
    }
    if (drag.current) {
      cancelDrag();
      return;
    }
    if (event.pointerType !== "touch" || event.isPrimary === false) return;
    drag.current = {
      locked: false,
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
    };
  };

  const onPointerMove = (event: PointerEvent<HTMLDivElement>) => {
    const current = drag.current;
    if (!current || current.pointerId !== event.pointerId) return;
    const distance = event.clientX - current.startX;
    const verticalDistance = event.clientY - current.startY;
    if (
      !current.locked &&
      Math.max(Math.abs(distance), Math.abs(verticalDistance)) < directionLockPixels
    ) {
      return;
    }
    if (!current.locked && Math.abs(verticalDistance) > Math.abs(distance)) {
      cancelDrag(event.pointerId);
      return;
    }
    if (!current.locked) {
      current.locked = true;
      event.currentTarget.setPointerCapture(event.pointerId);
    }
    event.preventDefault();
    setOffset(distance);
  };

  const onPointerEnd = (event: PointerEvent<HTMLDivElement>) => {
    const current = drag.current;
    if (!current || current.pointerId !== event.pointerId) return;
    const distance = event.clientX - current.startX;
    const crossedThreshold =
      current.locked && Math.abs(distance) >= event.currentTarget.clientWidth * 0.12;
    cancelDrag(event.pointerId);
    if (!crossedThreshold || !activeWindowId) return;
    const activeIndex = windowIds.indexOf(activeWindowId);
    if (activeIndex < 0) return;
    const direction = distance < 0 ? -1 : 1;
    const nextIndex = (activeIndex + (direction < 0 ? 1 : windowIds.length - 1)) % windowIds.length;
    const nextWindowId = windowIds[nextIndex];
    if (!nextWindowId) return;
    onSelectWindow(nextWindowId);
    animateSelection(direction);
  };

  return (
    <div
      className="relative flex min-h-0 min-w-0 flex-1 overflow-hidden touch-pan-y"
      onLostPointerCapture={(event) => {
        // Touch starts captured by xterm; transferring it here releases that child.
        if (event.target === event.currentTarget) cancelDrag(event.pointerId);
      }}
      onPointerCancel={(event) => cancelDrag(event.pointerId)}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerEnd}
      ref={wrapperRef}
    >
      <div
        className="flex h-full min-h-0 min-w-0 flex-1 will-change-transform"
        style={{
          transform: `translate3d(${offset}px, 0, 0)`,
          transition: transitioning ? `transform ${animationDuration}ms ease-out` : undefined,
        }}
      >
        {children}
      </div>
      {blanked ? (
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0"
          data-terminal-swipe-mask=""
          style={{ backgroundColor: xtermTheme.background }}
        />
      ) : null}
    </div>
  );
};
