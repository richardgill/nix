// @vitest-environment happy-dom
import { act, createElement } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, beforeEach, expect, test as testCases, vi } from "vitest";

import {
  MobileTmuxWindowBar,
  tmuxWindowLabel,
} from "./mobile-tmux-window-bar";

let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
let resize: (() => void) | undefined;
let resizeObservers = 0;

(globalThis as { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT =
  true;

beforeEach(() => {
  resize = undefined;
  resizeObservers = 0;
  class ResizeObserver {
    constructor(callback: () => void) {
      resizeObservers += 1;
      resize = callback;
    }

    disconnect() {}

    observe() {}
  }
  Object.assign(globalThis, { ResizeObserver });
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
});

afterEach(async () => {
  await act(async () => root.unmount());
  container.remove();
});

const labelCases = [
  { directory: null, expected: "editor", name: "editor" },
  { directory: "/work/project", expected: "project", name: "zsh" },
  { directory: "/work/project/", expected: "project", name: "zsh" },
  { directory: "", expected: "zsh", name: "zsh" },
  { directory: "/", expected: "zsh", name: "zsh" },
];
testCases.each(labelCases)(
  "labels $name from $directory",
  ({ directory, expected, name }) => {
    expect(
      tmuxWindowLabel({ activePaneDirectory: directory, windowName: name }),
    ).toBe(expected);
  },
);

testCases("keeps the active tab within the bar without resetting stable tabs", async () => {
  await act(async () => {
    root.render(
      createElement(MobileTmuxWindowBar, {
        activeWindowId: "@2",
        actionsDisabled: false,
        onCreatePiWindow: vi.fn(),
        onKillActivePane: vi.fn(),
        onSelectWindow: vi.fn(),
        tabs: [{ id: "@2", label: "project" }],
      }),
    );
  });
  const bar = container.querySelector<HTMLDivElement>("nav > div");
  const tab = container.querySelector<HTMLButtonElement>("button");
  Object.defineProperties(bar!, {
    clientWidth: { configurable: true, value: 100 },
    scrollLeft: { configurable: true, writable: true, value: 100 },
  });
  Object.defineProperties(tab!, {
    offsetLeft: { configurable: true, value: 50 },
    offsetWidth: { configurable: true, value: 20 },
  });
  resize?.();
  expect(bar?.scrollLeft).toBe(50);

  bar!.scrollLeft = 200;
  await act(async () => {
    root.render(
      createElement(MobileTmuxWindowBar, {
        activeWindowId: "@2",
        actionsDisabled: false,
        onCreatePiWindow: vi.fn(),
        onKillActivePane: vi.fn(),
        onSelectWindow: vi.fn(),
        tabs: [{ id: "@2", label: "project" }],
      }),
    );
  });
  expect(bar?.scrollLeft).toBe(200);
  expect(resizeObservers).toBe(1);
});

testCases.each([
  { terminalFocused: true, button: 0, prevented: true },
  { terminalFocused: false, button: 0, prevented: false },
  { terminalFocused: true, button: 1, prevented: false },
])(
  "preserves terminal focus only for primary presses: $terminalFocused / $button",
  async ({ terminalFocused, button, prevented }) => {
    const onSelectWindow = vi.fn();
    await act(async () => {
      root.render(
        createElement(MobileTmuxWindowBar, {
          activeWindowId: "@2",
          actionsDisabled: false,
          onCreatePiWindow: vi.fn(),
          onKillActivePane: vi.fn(),
          onSelectWindow,
          tabs: [{ id: "@3", label: "editor" }],
        }),
      );
    });
    const terminal = document.createElement("div");
    terminal.className = "xterm";
    const textarea = document.createElement("textarea");
    textarea.className = terminalFocused ? "xterm-helper-textarea" : "other-input";
    terminal.append(textarea);
    container.append(terminal);
    textarea.focus();
    const tab = container.querySelector<HTMLButtonElement>("button")!;
    const press = new PointerEvent("pointerdown", {
      bubbles: true,
      cancelable: true,
      button,
      pointerType: "touch",
    });
    await act(async () => tab.dispatchEvent(press));
    expect(press.defaultPrevented).toBe(prevented);
    expect(document.activeElement).toBe(textarea);
    expect(onSelectWindow).not.toHaveBeenCalled();
    await act(async () => tab.click());
    expect(onSelectWindow).toHaveBeenCalledExactlyOnceWith("@3");
    expect(tab.tabIndex).toBe(0);
  },
);

testCases("selects tabs and disables only mutation actions", async () => {
  const onSelectWindow = vi.fn();
  const onCreatePiWindow = vi.fn();
  const onKillActivePane = vi.fn();
  await act(async () => {
    root.render(
      createElement(MobileTmuxWindowBar, {
        activeWindowId: "@2",
        actionsDisabled: true,
        onCreatePiWindow,
        onKillActivePane,
        onSelectWindow,
        tabs: [
          { id: "@2", label: "project" },
          { id: "@3", label: "editor" },
        ],
      }),
    );
  });

  const buttons = container.querySelectorAll("button");
  expect(buttons[0]?.getAttribute("aria-current")).toBe("page");
  expect(buttons[2]?.hasAttribute("disabled")).toBe(true);
  expect(buttons[3]?.hasAttribute("disabled")).toBe(true);
  await act(async () => buttons[1]?.click());
  expect(onSelectWindow).toHaveBeenCalledWith("@3");
  expect(onCreatePiWindow).not.toHaveBeenCalled();
  expect(onKillActivePane).not.toHaveBeenCalled();
});
