import { act, createElement } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, expect, test as testCases, vi } from "vitest";

import { useTerminalPinchZoom } from "./use-terminal-pinch-zoom";

(globalThis as { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT =
  true;

let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
let frames = new Map<number, FrameRequestCallback>();
let nextFrame = 0;

const TerminalProbe = () => {
  const { containerRef, fontSize, resetFontSize } = useTerminalPinchZoom();
  return (
    <div data-font-size={fontSize} ref={containerRef}>
      <button onClick={resetFontSize} type="button">
        Reset terminal font size
      </button>
      <div data-terminal-target />
    </div>
  );
};

const eventWith = <T extends Event>(type: string, properties: object) => {
  const event = new Event(type, { bubbles: true, cancelable: true });
  Object.entries(properties).forEach(([key, value]) =>
    Object.defineProperty(event, key, { value }),
  );
  return event as T;
};

const setup = async () => {
  frames.clear();
  nextFrame = 0;
  vi.stubGlobal("requestAnimationFrame", (callback: FrameRequestCallback) => {
    nextFrame += 1;
    frames.set(nextFrame, callback);
    return nextFrame;
  });
  vi.stubGlobal("cancelAnimationFrame", (frame: number) => frames.delete(frame));
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
  await act(async () => {
    root.render(createElement(TerminalProbe));
    await Promise.resolve();
  });
  const terminal = container.firstElementChild as HTMLDivElement;
  return {
    target: terminal.querySelector<HTMLDivElement>("[data-terminal-target]")!,
    terminal,
  };
};

const flushFrame = async () => {
  const callbacks = [...frames.values()];
  frames.clear();
  await act(async () => callbacks.forEach((callback) => callback(0)));
};

afterEach(async () => {
  await act(async () => root?.unmount());
  container?.remove();
  vi.unstubAllGlobals();
  window.localStorage.clear();
});

testCases("ignores saved sizes and starts fresh after remounting", async () => {
  window.localStorage.setItem("overmux.terminal-font-size", "8");
  const { target, terminal } = await setup();
  expect(terminal.dataset.fontSize).toBe("15");

  await act(async () =>
    target.dispatchEvent(
      eventWith<WheelEvent>("wheel", { ctrlKey: true, deltaY: -100 }),
    ),
  );
  await flushFrame();
  expect(Number(terminal.dataset.fontSize)).toBeGreaterThan(15);
  expect(window.localStorage.getItem("overmux.terminal-font-size")).toBe("8");

  await act(async () => root.unmount());
  container.remove();
  const fresh = await setup();
  expect(fresh.terminal.dataset.fontSize).toBe("15");
});

testCases("captures ctrl-wheel zoom before xterm while passing ordinary scrolling through", async () => {
  const { target, terminal } = await setup();
  const targetWheel = vi.fn();
  target.addEventListener("wheel", targetWheel);
  const zoom = eventWith<WheelEvent>("wheel", {
    ctrlKey: true,
    deltaMode: WheelEvent.DOM_DELTA_PIXEL,
    deltaY: -10,
  });

  await act(async () => target.dispatchEvent(zoom));
  expect(zoom.defaultPrevented).toBe(true);
  expect(targetWheel).not.toHaveBeenCalled();
  expect(frames.size).toBe(1);

  await flushFrame();
  const firstFontSize = Number(terminal.dataset.fontSize);
  expect(firstFontSize).toBeCloseTo(15.252, 3);

  await act(async () =>
    target.dispatchEvent(
      eventWith<WheelEvent>("wheel", {
        ctrlKey: true,
        deltaMode: WheelEvent.DOM_DELTA_PIXEL,
        deltaY: -10,
      }),
    ),
  );
  await flushFrame();
  expect(Number(terminal.dataset.fontSize)).toBeGreaterThan(firstFontSize);

  await act(async () =>
    target.dispatchEvent(
      eventWith<WheelEvent>("wheel", { ctrlKey: false, deltaY: 10 }),
    ),
  );
  expect(targetWheel).toHaveBeenCalledOnce();
});

testCases("passes single-finger scrolling through and zooms only an active pinch", async () => {
  const { target, terminal } = await setup();
  const targetTouchMove = vi.fn();
  target.addEventListener("touchmove", targetTouchMove);

  const singleMove = eventWith<TouchEvent>("touchmove", { touches: [{}] });
  await act(async () => target.dispatchEvent(singleMove));
  expect(singleMove.defaultPrevented).toBe(false);
  expect(targetTouchMove).toHaveBeenCalledOnce();

  await act(async () =>
    target.dispatchEvent(
      eventWith<TouchEvent>("touchstart", {
        touches: [
          { clientX: 0, clientY: 0 },
          { clientX: 0, clientY: 10 },
        ],
      }),
    ),
  );
  const pinchMove = eventWith<TouchEvent>("touchmove", {
    touches: [
      { clientX: 0, clientY: 0 },
      { clientX: 0, clientY: 20 },
    ],
  });
  await act(async () => target.dispatchEvent(pinchMove));
  expect(pinchMove.defaultPrevented).toBe(true);
  expect(targetTouchMove).toHaveBeenCalledOnce();

  await flushFrame();
  expect(terminal.dataset.fontSize).toBe("30");

  await act(async () =>
    target.dispatchEvent(
      eventWith<TouchEvent>("touchmove", {
        touches: [
          { clientX: 0, clientY: 0 },
          { clientX: 0, clientY: 40 },
        ],
      }),
    ),
  );
  await flushFrame();
  expect(terminal.dataset.fontSize).toBe("32");

  await act(async () =>
    target.dispatchEvent(eventWith<TouchEvent>("touchend", { touches: [{}] })),
  );
  await act(async () =>
    target.dispatchEvent(
      eventWith<TouchEvent>("touchmove", {
        touches: [
          { clientX: 0, clientY: 0 },
          { clientX: 0, clientY: 20 },
        ],
      }),
    ),
  );
  expect(frames.size).toBe(0);
});

testCases("resets pending zoom to the default", async () => {
  const { target, terminal } = await setup();
  expect(terminal.dataset.fontSize).toBe("15");

  await act(async () =>
    target.dispatchEvent(
      eventWith<WheelEvent>("wheel", { ctrlKey: true, deltaY: -10 }),
    ),
  );
  expect(frames.size).toBe(1);
  await act(async () =>
    terminal.querySelector<HTMLButtonElement>("button")?.click(),
  );
  expect(frames.size).toBe(0);
  await flushFrame();
  expect(terminal.dataset.fontSize).toBe("15");
});
