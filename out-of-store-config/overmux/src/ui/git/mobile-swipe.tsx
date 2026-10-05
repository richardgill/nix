import { useLayoutEffect, useRef, useState, type ReactNode } from "react";
import {
  navigateChange,
  sameSelection,
  type ChangeEntry,
  type FileSelection,
} from "./model";

const directionLockPixels = 8;
const animationDuration = 45;
const selectionHoldMilliseconds = 350;
const interactiveSelector =
  "a, button, input, textarea, select, summary, [role='button'], [role='link'], [contenteditable]:not([contenteditable='false'])";

const isInteractive = (event: PointerEvent) =>
  event
    .composedPath()
    .some(
      (target) =>
        target instanceof Element && target.matches(interactiveSelector),
    );
const hasTextSelection = () => Boolean(document.getSelection()?.toString());

type Drag = {
  pointerId: number;
  x: number;
  y: number;
  started: number;
  locked: boolean;
};

type Incoming = { selection: FileSelection; offset: number };

export const MobileDiffSwipe = ({
  children,
  enabled,
  entries,
  selected,
  onSelectionChange,
}: {
  children: ReactNode;
  enabled: boolean;
  entries: ChangeEntry[];
  selected: FileSelection | undefined;
  onSelectionChange: (selection: FileSelection | undefined) => void;
}) => {
  const wrapper = useRef<HTMLDivElement>(null);
  const incoming = useRef<Incoming | undefined>(undefined);
  const [offset, setOffset] = useState(0);
  const [transitioning, setTransitioning] = useState(false);
  const active = enabled && entries.length > 1;

  useLayoutEffect(() => {
    const element = wrapper.current;
    if (!element) return;
    let drag: Drag | undefined;
    let timer: number | undefined;
    let frame: number | undefined;
    let animating = false;
    const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
    const controller = new AbortController();
    const options = { capture: true, signal: controller.signal };

    const releaseDrag = () => {
      const previous = drag;
      drag = undefined;
      // Clear first: releasing capture can synchronously emit lostpointercapture.
      if (previous && element.hasPointerCapture(previous.pointerId))
        element.releasePointerCapture(previous.pointerId);
    };
    const cancel = () => {
      releaseDrag();
      window.clearTimeout(timer);
      if (frame !== undefined) cancelAnimationFrame(frame);
      timer = undefined;
      frame = undefined;
      incoming.current = undefined;
      animating = false;
      setTransitioning(false);
      setOffset(0);
    };
    const enter = incoming.current;
    incoming.current = undefined;
    if (
      active &&
      enter &&
      sameSelection(enter.selection, selected) &&
      !reducedMotion.matches
    ) {
      animating = true;
      setTransitioning(false);
      setOffset(enter.offset);
      // Paint the new file on the reverse side before sliding it into place.
      frame = requestAnimationFrame(() => {
        frame = requestAnimationFrame(() => {
          setTransitioning(true);
          setOffset(0);
          timer = window.setTimeout(cancel, animationDuration);
        });
      });
    } else {
      setTransitioning(false);
      setOffset(0);
    }

    const down = (event: PointerEvent) => {
      if (
        !active ||
        animating ||
        event.pointerType !== "touch" ||
        !event.isPrimary ||
        isInteractive(event) ||
        hasTextSelection()
      )
        return;
      drag = {
        pointerId: event.pointerId,
        x: event.clientX,
        y: event.clientY,
        started: event.timeStamp,
        locked: false,
      };
    };
    const move = (event: PointerEvent) => {
      if (!drag || drag.pointerId !== event.pointerId) return;
      if (
        hasTextSelection() ||
        (!drag.locked &&
          event.timeStamp - drag.started >= selectionHoldMilliseconds)
      ) {
        cancel();
        return;
      }
      const distance = event.clientX - drag.x;
      const vertical = event.clientY - drag.y;
      if (!drag.locked) {
        if (
          Math.max(Math.abs(distance), Math.abs(vertical)) < directionLockPixels
        )
          return;
        if (Math.abs(vertical) > Math.abs(distance)) {
          cancel();
          return;
        }
        drag.locked = true;
        element.setPointerCapture(event.pointerId);
      }
      event.preventDefault();
      if (!reducedMotion.matches) setOffset(distance);
    };
    const up = (event: PointerEvent) => {
      if (!drag || drag.pointerId !== event.pointerId) return;
      const distance = event.clientX - drag.x;
      const width = element.clientWidth;
      const accepted =
        drag.locked &&
        width > 0 &&
        Math.abs(distance) >= width * 0.12 &&
        !hasTextSelection();
      releaseDrag();
      if (!accepted) {
        cancel();
        return;
      }
      const next = navigateChange(entries, selected, distance < 0 ? 1 : -1);
      if (!next) return;
      if (reducedMotion.matches) {
        cancel();
        onSelectionChange(next);
        return;
      }
      animating = true;
      setTransitioning(true);
      setOffset(distance < 0 ? -width : width);
      timer = window.setTimeout(() => {
        // Selection stays controlled. Its layout effect starts the incoming slide.
        incoming.current = {
          selection: next,
          offset: distance < 0 ? width : -width,
        };
        onSelectionChange(next);
      }, animationDuration);
    };
    const secondPointer = (event: PointerEvent) => {
      if (event.pointerType === "touch" && !event.isPrimary) cancel();
    };
    const pinch = (event: TouchEvent) => {
      // Leave both touch events and their defaults to useDiffTextSize.
      if (event.touches.length > 1) cancel();
    };
    const cancelledPointer = (event: PointerEvent) => {
      if (drag?.pointerId === event.pointerId) cancel();
    };
    const lostCapture = (event: PointerEvent) => {
      // Transferring implicit capture from a diff child is not cancellation.
      if (event.target === element) cancelledPointer(event);
    };
    const selectionChanged = () => {
      if (hasTextSelection()) cancel();
    };
    document.addEventListener("pointerdown", secondPointer, options);
    document.addEventListener("touchstart", pinch, options);
    document.addEventListener("pointerup", up, options);
    document.addEventListener("pointercancel", cancelledPointer, options);
    document.addEventListener("selectionchange", selectionChanged, options);
    element.addEventListener("pointerdown", down, options);
    element.addEventListener("pointermove", move, options);
    element.addEventListener("lostpointercapture", lostCapture, options);
    reducedMotion.addEventListener?.("change", cancel);
    return () => {
      controller.abort();
      reducedMotion.removeEventListener?.("change", cancel);
      releaseDrag();
      window.clearTimeout(timer);
      if (frame !== undefined) cancelAnimationFrame(frame);
    };
  }, [
    active,
    entries,
    selected?.comparison,
    selected?.path,
    onSelectionChange,
  ]);

  return (
    <div className="git-diff-swipe" data-swipe-enabled={active} ref={wrapper}>
      <div
        className="git-diff-swipe-content"
        style={{
          transform: `translate3d(${offset}px, 0, 0)`,
          transition: transitioning
            ? `transform ${animationDuration}ms ease-out`
            : undefined,
        }}
      >
        {children}
      </div>
    </div>
  );
};
