// @vitest-environment happy-dom
import { act, createElement, createRef } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, beforeEach, expect, test as testCases, vi } from "vitest";

import type { XtermTerminalHandle } from "@overmux/xterm/react";

import {
  MobileTerminalKeys,
  useMobileTerminalKeys,
} from "./mobile-terminal-keys";

let keys: ReturnType<typeof useMobileTerminalKeys>;
const Harness = () => {
  keys = useMobileTerminalKeys(terminalRef);
  return createElement(MobileTerminalKeys, keys);
};

let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
let terminalRef: ReturnType<typeof createRef<XtermTerminalHandle>>;
let input: ReturnType<typeof vi.fn>;
let focus: ReturnType<typeof vi.fn>;

(globalThis as { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT =
  true;

beforeEach(() => {
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
  terminalRef = createRef<XtermTerminalHandle>();
  input = vi.fn();
  focus = vi.fn();
  terminalRef.current = { focus, input } as XtermTerminalHandle;
});

afterEach(async () => {
  await act(async () => root.unmount());
  container.remove();
});

const render = async () => {
  await act(async () => root.render(createElement(Harness)));
};

const button = (label: string) =>
  container.querySelector<HTMLButtonElement>(`button[aria-label="${label}"]`)!;

testCases(
  "sends a modified key once, clears modifiers, and refocuses",
  async () => {
    await render();
    await act(async () => button("Ctrl").click());
    await act(async () => button("Left arrow").click());

    expect(input).toHaveBeenCalledExactlyOnceWith("\u001b[1;5D");
    expect(focus).toHaveBeenCalledTimes(2);
    expect(button("Ctrl").getAttribute("aria-pressed")).toBe("false");
  },
);

testCases(
  "clears modifiers synchronously at the ownership callback",
  async () => {
    await render();
    await act(async () => {
      button("Alt").click();
      keys.clear();
      expect(keys.transformInput({ kind: "text", data: "x" })).toBe("x");
    });

    expect(button("Alt").getAttribute("aria-pressed")).toBe("false");
  },
);

testCases.each([
  { kind: "text", data: "c", expected: "\u001b\u0003" },
  { kind: "text", data: "hello", expected: "hello" },
  { kind: "paste", data: "c", expected: "c" },
  { kind: "paste", data: "hello", expected: "hello" },
  { kind: "key", data: "c", expected: "\u001b\u0003" },
] as const)(
  "consumes both modifiers once for $kind $data",
  async ({ kind, data, expected }) => {
    await render();
    await act(async () => {
      button("Ctrl").click();
      button("Alt").click();
      const event =
        kind === "key"
          ? { kind, data, domEvent: new KeyboardEvent("keydown") }
          : { kind, data };
      expect(keys.transformInput(event)).toBe(expected);
      expect(keys.transformInput({ kind: "text", data: "c" })).toBe("c");
    });
    expect(button("Ctrl").getAttribute("aria-pressed")).toBe("false");
    expect(button("Alt").getAttribute("aria-pressed")).toBe("false");
  },
);

testCases(
  "rapid toggles and native modifier encoding never double-apply",
  async () => {
    await render();
    await act(async () => {
      button("Ctrl").click();
      button("Ctrl").click();
      expect(keys.transformInput({ kind: "text", data: "c" })).toBe("c");
      button("Ctrl").click();
      button("Alt").click();
      expect(
        keys.transformInput({
          kind: "key",
          data: "\u0003",
          domEvent: new KeyboardEvent("keydown", { ctrlKey: true }),
        }),
      ).toBe("\u0003");
      keys.send("/");
    });
    expect(input).toHaveBeenCalledExactlyOnceWith("/");
  },
);

testCases("prevents toolbar presses from taking terminal focus", async () => {
  await render();
  const press = new PointerEvent("pointerdown", {
    bubbles: true,
    cancelable: true,
  });
  await act(async () => button("Tab").dispatchEvent(press));
  expect(press.defaultPrevented).toBe(true);
});
