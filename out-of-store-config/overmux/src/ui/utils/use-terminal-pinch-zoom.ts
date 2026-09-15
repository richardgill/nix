import { useEffect, useRef, useState } from "react";

const terminalFontSize = {
  default: 15,
  maximum: 32,
  minimum: 8,
};

type PinchStart = { distance: number; fontSize: number };

const clampFontSize = (fontSize: number) =>
  Math.min(terminalFontSize.maximum, Math.max(terminalFontSize.minimum, fontSize));

const touchDistance = (touches: TouchList) => {
  const first = touches[0];
  const second = touches[1];
  return first && second
    ? Math.hypot(second.clientX - first.clientX, second.clientY - first.clientY)
    : 0;
};

const wheelDeltaPixels = (event: WheelEvent) =>
  event.deltaY *
  (event.deltaMode === WheelEvent.DOM_DELTA_LINE
    ? 16
    : event.deltaMode === WheelEvent.DOM_DELTA_PAGE
      ? window.innerHeight
      : 1);

export const useTerminalPinchZoom = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [fontSize, setFontSize] = useState(terminalFontSize.default);
  const gesture = useRef<{
    fontSize: number;
    frame: number | undefined;
    pendingFontSize: number | undefined;
  }>({ fontSize, frame: undefined, pendingFontSize: undefined });
  gesture.current.fontSize = fontSize;

  useEffect(() => {
    const container = containerRef.current;
    if (!container) {
      return;
    }
    let pinchStart: PinchStart | undefined;
    const controller = new AbortController();
    const scheduleFontSize = (next: number) => {
      gesture.current.pendingFontSize = clampFontSize(next);
      if (gesture.current.frame !== undefined) return;
      gesture.current.frame = requestAnimationFrame(() => {
        gesture.current.frame = undefined;
        if (gesture.current.pendingFontSize !== undefined) {
          setFontSize(gesture.current.pendingFontSize);
        }
        gesture.current.pendingFontSize = undefined;
      });
    };
    const startPinch = (event: TouchEvent) => {
      pinchStart =
        event.touches.length === 2
          ? {
              distance: touchDistance(event.touches),
              fontSize: gesture.current.fontSize,
            }
          : undefined;
    };
    const movePinch = (event: TouchEvent) => {
      if (event.touches.length < 2) return;
      event.preventDefault();
      event.stopPropagation();
      if (
        !pinchStart ||
        event.touches.length !== 2 ||
        pinchStart.distance === 0
      ) {
        return;
      }
      scheduleFontSize(
        pinchStart.fontSize * (touchDistance(event.touches) / pinchStart.distance),
      );
    };
    const endPinch = (event: TouchEvent) => {
      if (event.touches.length < 2) pinchStart = undefined;
    };
    const zoomWheel = (event: WheelEvent) => {
      if (!event.ctrlKey) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      scheduleFontSize(
        (gesture.current.pendingFontSize ?? gesture.current.fontSize) *
          Math.exp(-wheelDeltaPixels(event) / 600),
      );
    };
    container.addEventListener("touchstart", startPinch, {
      capture: true,
      signal: controller.signal,
    });
    container.addEventListener("touchmove", movePinch, {
      capture: true,
      passive: false,
      signal: controller.signal,
    });
    container.addEventListener("touchend", endPinch, {
      capture: true,
      signal: controller.signal,
    });
    container.addEventListener("touchcancel", endPinch, {
      capture: true,
      signal: controller.signal,
    });
    container.addEventListener("wheel", zoomWheel, {
      capture: true,
      passive: false,
      signal: controller.signal,
    });
    return () => {
      controller.abort();
      if (gesture.current.frame !== undefined) {
        cancelAnimationFrame(gesture.current.frame);
      }
      gesture.current.frame = undefined;
      gesture.current.pendingFontSize = undefined;
    };
  }, []);

  const resetFontSize = () => {
    if (gesture.current.frame !== undefined) {
      cancelAnimationFrame(gesture.current.frame);
    }
    gesture.current.frame = undefined;
    gesture.current.pendingFontSize = undefined;
    setFontSize(terminalFontSize.default);
  };

  return { containerRef, fontSize, resetFontSize };
};
