import { act } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, expect, test as testCases, vi } from "vitest";
import { useDiffTextSize } from "./mobile";

Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });
let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
const Probe = () => {
  const { ref, fontSize, resetFontSize } = useDiffTextSize();
  return (
    <div ref={ref} onDoubleClick={resetFontSize}>
      {fontSize}
    </div>
  );
};
const touch = async (type: string, distance: number, count = 2) => {
  const event = new Event(type, { bubbles: true, cancelable: true });
  Object.defineProperty(event, "touches", {
    value:
      count === 2
        ? [
            { clientX: 0, clientY: 0 },
            { clientX: distance, clientY: 0 },
          ]
        : [{ clientX: 0, clientY: 0 }],
  });
  await act(async () => container.firstElementChild?.dispatchEvent(event));
  return event;
};
afterEach(async () => {
  await act(async () => root.unmount());
  container.remove();
  vi.unstubAllGlobals();
});

testCases.each([
  { mobile: false, initial: 12 },
  { mobile: true, initial: 10 },
])(
  "pinch clamps text size and double-click restores $initial px",
  async ({ mobile, initial }) => {
    vi.stubGlobal("matchMedia", () => ({ matches: mobile }));
    container = document.createElement("div");
    document.body.append(container);
    root = createRoot(container);
    await act(async () => root.render(<Probe />));
    expect(container.textContent).toBe(String(initial));
    await touch("touchstart", 100);
    expect((await touch("touchmove", 1000)).defaultPrevented).toBe(true);
    expect(container.textContent).toBe("16");
    await touch("touchmove", 1);
    expect(container.textContent).toBe("8");
    await touch("touchend", 0, 1);
    expect((await touch("touchmove", 50, 1)).defaultPrevented).toBe(false);
    await act(async () =>
      container.firstElementChild?.dispatchEvent(
        new MouseEvent("dblclick", { bubbles: true }),
      ),
    );
    expect(container.textContent).toBe(String(initial));
  },
);
