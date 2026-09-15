// @vitest-environment happy-dom
import { act, createElement } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, beforeEach, expect, test as testCases, vi } from "vitest";

import { MobileTmuxWindowSwipe } from "./mobile-tmux-window-swipe";

let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
let mobile = true;

(globalThis as { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT = true;

beforeEach(() => {
  mobile = true;
  Object.assign(window, {
    matchMedia: (query: string) => ({
      matches: query.includes("max-width") ? mobile : false,
    }),
  });
  HTMLElement.prototype.setPointerCapture = vi.fn();
  HTMLElement.prototype.releasePointerCapture = vi.fn();
  HTMLElement.prototype.hasPointerCapture = vi.fn(() => true);
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
});

afterEach(async () => {
  await act(async () => root.unmount());
  container.remove();
  vi.useRealTimers();
});

const pointer = (type: string, values: Record<string, number | boolean>) => {
  const event = new PointerEvent(type, { bubbles: true, cancelable: true });
  Object.entries({ pointerType: "touch", pointerId: 1, isPrimary: true, ...values }).forEach(
    ([key, value]) => Object.defineProperty(event, key, { value }),
  );
  return event;
};

const setup = async () => {
  const onSelectWindow = vi.fn();
  await act(async () => {
    root.render(
      createElement(
        MobileTmuxWindowSwipe,
        { activeWindowId: "two", onSelectWindow, windowIds: ["one", "two", "three"] },
        createElement("div", null, "terminal"),
      ),
    );
  });
  const swipe = container.firstElementChild as HTMLDivElement;
  Object.defineProperty(swipe, "clientWidth", { configurable: true, value: 100 });
  return { onSelectWindow, swipe };
};

const drag = async (swipe: HTMLDivElement, endX: number, endY = 0) => {
  await act(async () => {
    swipe.dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    swipe.dispatchEvent(pointer("pointermove", { clientX: endX, clientY: endY }));
    swipe.dispatchEvent(pointer("pointerup", { clientX: endX, clientY: endY }));
  });
};

testCases.each([
  { endX: -20, selected: "three" },
  { endX: 20, selected: "one" },
])("selects $selected immediately after a $endX px drag", async ({ endX, selected }) => {
  vi.useFakeTimers();
  const { onSelectWindow, swipe } = await setup();
  await drag(swipe, endX);

  expect(onSelectWindow).toHaveBeenCalledExactlyOnceWith(selected);
  expect((swipe.firstElementChild as HTMLElement).style.transform).toContain(
    `${endX < 0 ? "-" : ""}100px`,
  );
  await act(async () => vi.advanceTimersByTime(180));
  expect(onSelectWindow).toHaveBeenCalledExactlyOnceWith(selected);
});

testCases.each([
  { captured: true, endX: 11, endY: 0, name: "below threshold" },
  { captured: false, endX: 2, endY: 9, name: "vertical drag after direction lock" },
])("does not select for $name", async ({ captured, endX, endY }) => {
  const { onSelectWindow, swipe } = await setup();
  await drag(swipe, endX, endY);
  expect(onSelectWindow).not.toHaveBeenCalled();
  expect(HTMLElement.prototype.setPointerCapture).toHaveBeenCalledTimes(
    captured ? 1 : 0,
  );
});

testCases("masks stale content after slide-out for 100ms without waiting for navigation", async () => {
  vi.useFakeTimers();
  const { onSelectWindow, swipe } = await setup();
  const terminal = swipe.firstElementChild;
  await drag(swipe, -20);
  expect(onSelectWindow).toHaveBeenCalledExactlyOnceWith("three");
  expect(swipe.querySelector("[data-terminal-swipe-mask]")).toBeNull();
  await act(async () => vi.advanceTimersByTime(45));
  expect(swipe.querySelector("[data-terminal-swipe-mask]")).not.toBeNull();
  await act(async () => vi.advanceTimersByTime(99));
  expect(swipe.querySelector("[data-terminal-swipe-mask]")).not.toBeNull();
  await act(async () => vi.advanceTimersByTime(1));
  expect(swipe.querySelector("[data-terminal-swipe-mask]")).toBeNull();
  expect(swipe.firstElementChild).toBe(terminal);
  expect(onSelectWindow).toHaveBeenCalledTimes(1);
});

testCases("keeps the outgoing animation when release asynchronously loses capture", async () => {
  const { onSelectWindow, swipe } = await setup();
  HTMLElement.prototype.releasePointerCapture = vi.fn(function (pointerId: number) {
    queueMicrotask(() =>
      this.dispatchEvent(pointer("lostpointercapture", { pointerId })),
    );
  });

  await drag(swipe, -20);
  await act(async () => {});
  expect(onSelectWindow).toHaveBeenCalledExactlyOnceWith("three");
  expect((swipe.firstElementChild as HTMLElement).style.transform).toContain(
    "-100px",
  );
});

testCases("continues when implicit touch capture transfers from the terminal", async () => {
  const { onSelectWindow, swipe } = await setup();
  const terminal = swipe.firstElementChild!.firstElementChild!;
  await act(async () => {
    terminal.dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    terminal.dispatchEvent(pointer("pointermove", { clientX: -10, clientY: 0 }));
  });
  expect(HTMLElement.prototype.setPointerCapture).toHaveBeenCalledWith(1);
  await act(async () => {
    terminal.dispatchEvent(pointer("lostpointercapture", {}));
    swipe.dispatchEvent(pointer("pointermove", { clientX: -30, clientY: 0 }));
    swipe.dispatchEvent(pointer("pointerup", { clientX: -30, clientY: 0 }));
  });
  expect(onSelectWindow).toHaveBeenCalledExactlyOnceWith("three");
});

testCases("cancels when a second finger joins and ignores desktop gestures", async () => {
  const { onSelectWindow, swipe } = await setup();
  await act(async () => {
    swipe.dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    swipe.dispatchEvent(pointer("pointermove", { clientX: -20, clientY: 0 }));
    swipe.dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0, pointerId: 2, isPrimary: false }));
    swipe.dispatchEvent(pointer("pointerup", { clientX: -20, clientY: 0 }));
  });
  expect(onSelectWindow).not.toHaveBeenCalled();

  mobile = false;
  await drag(swipe, -20);
  expect(onSelectWindow).not.toHaveBeenCalled();
  expect(HTMLElement.prototype.setPointerCapture).toHaveBeenCalledTimes(1);
});
