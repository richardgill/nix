import { act } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, beforeEach, expect, test as testCases, vi } from "vitest";
import { MobileDiffSwipe } from "./mobile-swipe";
import { useDiffTextSize } from "./mobile";
import { orderedChanges } from "./model";
import { changes, fileChange } from "./fixtures.test-support";

Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });
const entries = orderedChanges(
  changes({
    staged: [fileChange("a.ts")],
    unstaged: [fileChange("a.ts"), fileChange("b.ts")],
  }),
);
let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
let reducedMotion = false;
const select = vi.fn();
const Content = () => {
  const { ref, fontSize } = useDiffTextSize();
  return (
    <div className="git-diff" ref={ref} data-font-size={fontSize}>
      <p>Selectable diff content</p>
      <button>Context</button>
      <div data-shadow-host />
    </div>
  );
};

beforeEach(() => {
  vi.useFakeTimers();
  reducedMotion = false;
  select.mockReset();
  vi.stubGlobal("matchMedia", (query: string) => ({
    matches: query.includes("reduced-motion") ? reducedMotion : false,
  }));
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
  document.getSelection()?.removeAllRanges();
  vi.useRealTimers();
  vi.unstubAllGlobals();
});
const render = async (index = 0, enabled = true, files = entries) => {
  await act(async () =>
    root.render(
      <MobileDiffSwipe
        enabled={enabled}
        entries={files}
        selected={files[index]}
        onSelectionChange={select}
      >
        <Content />
      </MobileDiffSwipe>,
    ),
  );
  const element = container.firstElementChild as HTMLDivElement;
  Object.defineProperty(element, "clientWidth", {
    configurable: true,
    value: 100,
  });
  return element;
};
const pointer = async (
  target: Element,
  type: string,
  values: PointerEventInit = {},
) => {
  const event = new PointerEvent(type, {
    bubbles: true,
    composed: true,
    cancelable: true,
    pointerType: "touch",
    pointerId: 1,
    isPrimary: true,
    clientX: 0,
    clientY: 0,
    ...values,
  });
  await act(async () => target.dispatchEvent(event));
  return event;
};
const drag = async (
  target: Element,
  x: number,
  y = 0,
  pointerType = "touch",
) => {
  await pointer(target, "pointerdown", { pointerType });
  const move = await pointer(target, "pointermove", {
    clientX: x,
    clientY: y,
    pointerType,
  });
  await pointer(target, "pointerup", { clientX: x, clientY: y, pointerType });
  await act(async () => vi.advanceTimersByTime(45));
  return move;
};
const slide = () =>
  container.querySelector<HTMLElement>(".git-diff-swipe-content")!;
const touch = async (target: Element, type: string, distance: number) => {
  const event = new Event(type, { bubbles: true, cancelable: true });
  Object.defineProperty(event, "touches", {
    value: [
      { clientX: 0, clientY: 0 },
      { clientX: distance, clientY: 0 },
    ],
  });
  await act(async () => target.dispatchEvent(event));
  return event;
};

testCases.each([
  { index: 0, x: -12, next: 1, label: "left goes next at threshold" },
  { index: 1, x: -20, next: 2, label: "left crosses unstaged into staged" },
  { index: 2, x: -20, next: 0, label: "left wraps to first" },
  { index: 1, x: 20, next: 0, label: "right goes previous" },
  { index: 0, x: 20, next: 2, label: "right wraps to last" },
])("$label", async ({ index, x, next }) => {
  await drag(await render(index), x);
  expect(select).toHaveBeenCalledExactlyOnceWith(entries[next]);
});

testCases.each([
  { x: 7, y: 0, captured: false, label: "under 8px direction lock" },
  { x: 11, y: 0, captured: true, label: "under 12% threshold" },
  { x: 2, y: 9, captured: false, label: "vertical scroll" },
])("does not navigate for $label", async ({ x, y, captured }) => {
  const move = await drag(await render(), x, y);
  expect(select).not.toHaveBeenCalled();
  expect(HTMLElement.prototype.setPointerCapture).toHaveBeenCalledTimes(
    captured ? 1 : 0,
  );
  expect(move.defaultPrevented).toBe(captured);
  expect(slide().style.transform).toContain("(0px,");
});

testCases.each(["mouse", "disabled", "one file", "empty"])(
  "ignores %s",
  async (kind) => {
    const files =
      kind === "empty"
        ? []
        : kind === "one file"
          ? entries.slice(0, 1)
          : entries;
    await drag(
      await render(0, kind !== "disabled", files),
      -30,
      0,
      kind === "mouse" ? "mouse" : "touch",
    );
    expect(select).not.toHaveBeenCalled();
    expect(HTMLElement.prototype.setPointerCapture).not.toHaveBeenCalled();
  },
);

testCases.each([
  "button",
  "shadow button",
  "editable",
  "selection",
  "long press",
])("leaves %s alone", async (kind) => {
  const element = await render();
  let target: Element = element;
  if (kind === "button") target = container.querySelector("button")!;
  if (kind === "shadow button") {
    const shadow = container
      .querySelector("[data-shadow-host]")!
      .attachShadow({ mode: "open" });
    const button = document.createElement("button");
    const icon = document.createElement("span");
    button.append(icon);
    shadow.append(button);
    target = icon;
  }
  if (kind === "editable") {
    target = container.querySelector("p")!;
    target.setAttribute("contenteditable", "true");
  }
  if (kind === "selection") {
    const range = document.createRange();
    range.selectNodeContents(container.querySelector("p")!);
    document.getSelection()?.addRange(range);
  }
  await pointer(target, "pointerdown");
  const move = new PointerEvent("pointermove", {
    bubbles: true,
    composed: true,
    cancelable: true,
    pointerId: 1,
    pointerType: "touch",
    clientX: -30,
  });
  if (kind === "long press")
    Object.defineProperty(move, "timeStamp", {
      value: performance.now() + 500,
    });
  await act(async () => target.dispatchEvent(move));
  await pointer(target, "pointerup", { clientX: -30 });
  await act(async () => vi.advanceTimersByTime(200));
  expect(select).not.toHaveBeenCalled();
  expect(move.defaultPrevented).toBe(false);
});

testCases.each([
  "pointercancel",
  "lostpointercapture",
  "second finger on control",
  "external selection",
])("cancels a captured swipe on %s", async (kind) => {
  const element = await render();
  await pointer(element, "pointerdown");
  await pointer(element, "pointermove", { clientX: -30 });
  if (kind === "external selection") await render(2);
  else if (kind === "second finger on control")
    await pointer(container.querySelector("button")!, "pointerdown", {
      pointerId: 2,
      isPrimary: false,
    });
  else await pointer(element, kind);
  await pointer(element, "pointerup", { clientX: -30 });
  await act(async () => vi.advanceTimersByTime(200));
  expect(select).not.toHaveBeenCalled();
  expect(slide().style.transform).toContain("(0px,");
  expect(HTMLElement.prototype.releasePointerCapture).toHaveBeenCalledWith(1);
});

testCases(
  "second touch cancels swipe without preventing two-finger text zoom",
  async () => {
    const element = await render();
    const content = container.querySelector<HTMLElement>(".git-diff")!;
    await pointer(content, "pointerdown");
    await pointer(content, "pointermove", { clientX: -30 });
    expect((await touch(content, "touchstart", 100)).defaultPrevented).toBe(
      false,
    );
    expect((await touch(content, "touchmove", 125)).defaultPrevented).toBe(
      true,
    );
    expect(content.dataset.fontSize).toBe("15");
    await pointer(element, "pointerup", { clientX: -30 });
    await act(async () => vi.advanceTimersByTime(200));
    expect(select).not.toHaveBeenCalled();
    expect(slide().style.transform).toContain("(0px,");
  },
);

testCases(
  "slides the live pane out then in without replacing its scroll container",
  async () => {
    const element = await render();
    const content = container.querySelector<HTMLElement>(".git-diff")!;
    content.scrollTop = 80;
    await pointer(element, "pointerdown");
    await pointer(element, "pointermove", { clientX: -30 });
    await pointer(content, "lostpointercapture");
    await pointer(element, "pointerup", { clientX: -30 });
    expect(slide().style.transform).toContain("(-100px,");
    expect(slide().style.transition).toContain("45ms");
    expect(select).not.toHaveBeenCalled();
    await act(async () => vi.advanceTimersByTime(45));
    expect(select).toHaveBeenCalledExactlyOnceWith(entries[1]);
    await render(1);
    expect(slide().style.transform).toContain("(100px,");
    await act(async () => vi.advanceTimersByTime(100));
    expect(slide().style.transform).toContain("(0px,");
    expect(container.querySelector(".git-diff")).toBe(content);
    expect(content.scrollTop).toBe(80);
  },
);

testCases(
  "reduced motion selects immediately with no drag or slide animation",
  async () => {
    reducedMotion = true;
    const element = await render();
    await pointer(element, "pointerdown");
    await pointer(element, "pointermove", { clientX: -30 });
    expect(slide().style.transform).toContain("(0px,");
    await pointer(element, "pointerup", { clientX: -30 });
    expect(select).toHaveBeenCalledExactlyOnceWith(entries[1]);
    expect(slide().style.transition).toBe("");
    expect(vi.getTimerCount()).toBe(0);
  },
);

testCases.each(["unmount", "external selection"])(
  "%s cancels pending navigation and animation",
  async (kind) => {
    const element = await render();
    await pointer(element, "pointerdown");
    await pointer(element, "pointermove", { clientX: -30 });
    await pointer(element, "pointerup", { clientX: -30 });
    if (kind === "unmount") await act(async () => root.render(null));
    else await render(2);
    await act(async () => vi.advanceTimersByTime(200));
    expect(select).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  },
);
