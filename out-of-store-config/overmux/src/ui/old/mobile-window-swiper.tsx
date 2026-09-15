import { type PointerEvent, type ReactNode, useRef, useState } from "react";

type Axis = "horizontal" | "vertical" | undefined;
type Gesture = { axis: Axis; startX: number; startY: number };

const transitionDuration = 90;
const swipeThreshold = 0.12;

const animationDuration = () =>
  matchMedia("(prefers-reduced-motion: reduce)").matches
    ? 0
    : transitionDuration;

const waitForAnimation = () =>
  new Promise<void>((resolve) => {
    setTimeout(resolve, animationDuration());
  });

const isInteractive = (target: EventTarget | null) =>
  target instanceof Element &&
  Boolean(
    target.closest("a, button, input, textarea, select, [contenteditable]"),
  );

export const MobileWindowSwiper = ({
  children,
  enabled,
  onNavigate,
}: {
  children: ReactNode;
  enabled: boolean;
  onNavigate: (direction: -1 | 1) => Promise<boolean>;
}) => {
  const gestureRef = useRef<Gesture | undefined>(undefined);
  const navigatingRef = useRef(false);
  const [motion, setMotion] = useState({ transition: false, x: 0 });
  const reset = async () => {
    setMotion({ transition: true, x: 0 });
    await waitForAnimation();
    setMotion({ transition: false, x: 0 });
  };
  const onPointerDown = (event: PointerEvent<HTMLDivElement>) => {
    if (
      !enabled ||
      navigatingRef.current ||
      !event.isPrimary ||
      isInteractive(event.target)
    ) {
      return;
    }
    gestureRef.current = {
      axis: undefined,
      startX: event.clientX,
      startY: event.clientY,
    };
  };
  const onPointerMove = (event: PointerEvent<HTMLDivElement>) => {
    const gesture = gestureRef.current;
    if (!gesture || navigatingRef.current || gesture.axis === "vertical")
      return;
    const x = event.clientX - gesture.startX;
    const y = event.clientY - gesture.startY;
    if (!gesture.axis && Math.max(Math.abs(x), Math.abs(y)) < 8) return;
    if (!gesture.axis) {
      gesture.axis = Math.abs(x) > Math.abs(y) ? "horizontal" : "vertical";
    }
    if (gesture.axis === "vertical") return;
    event.currentTarget.setPointerCapture(event.pointerId);
    event.preventDefault();
    const width = event.currentTarget.clientWidth;
    setMotion({ transition: false, x: Math.max(-width, Math.min(width, x)) });
  };
  const onPointerEnd = async (event: PointerEvent<HTMLDivElement>) => {
    const gesture = gestureRef.current;
    gestureRef.current = undefined;
    if (!gesture || gesture.axis !== "horizontal" || navigatingRef.current)
      return;
    const width = event.currentTarget.clientWidth;
    const x = event.clientX - gesture.startX;
    if (!width || Math.abs(x) < width * swipeThreshold) {
      await reset();
      return;
    }
    navigatingRef.current = true;
    const direction = x < 0 ? 1 : -1;
    setMotion({ transition: true, x: direction * -width });
    await waitForAnimation();
    if (!(await onNavigate(direction))) {
      await reset();
      navigatingRef.current = false;
      return;
    }
    setMotion({ transition: false, x: direction * width });
    requestAnimationFrame(() => setMotion({ transition: true, x: 0 }));
    await waitForAnimation();
    setMotion({ transition: false, x: 0 });
    navigatingRef.current = false;
  };
  return (
    <div
      className="mobile-window-swiper"
      onPointerCancel={() => {
        gestureRef.current = undefined;
        void reset();
      }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={(event) => void onPointerEnd(event)}
    >
      <div
        className="mobile-window-swiper-content"
        style={{
          transform: `translate3d(${motion.x}px, 0, 0)`,
          transition: motion.transition
            ? `transform ${transitionDuration}ms ease-out`
            : undefined,
        }}
      >
        {children}
      </div>
    </div>
  );
};
