import { useEffect, useRef } from "react";

export const useIosVisualViewport = () => {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const element = ref.current;
    const viewport = window.visualViewport;
    if (document.documentElement.dataset.omPlatform !== "ios" || !element || !viewport) return;

    // iOS resizes the visual viewport, not the CSS viewport, for its keyboard.
    const update = () => {
      element.style.setProperty("--ios-viewport-height", `${viewport.height}px`);
      element.style.setProperty("--ios-viewport-top", `${viewport.offsetTop}px`);
    };
    update();
    viewport.addEventListener("resize", update);
    viewport.addEventListener("scroll", update);

    return () => {
      viewport.removeEventListener("resize", update);
      viewport.removeEventListener("scroll", update);
      element.style.removeProperty("--ios-viewport-height");
      element.style.removeProperty("--ios-viewport-top");
    };
  }, []);

  return ref;
};
