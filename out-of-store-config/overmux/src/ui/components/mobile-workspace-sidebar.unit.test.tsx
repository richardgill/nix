// @vitest-environment happy-dom
import { act, createElement } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, beforeEach, expect, test as testCases, vi } from "vitest";

import { MobileWorkspaceSidebar } from "./mobile-workspace-sidebar";

let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;

(globalThis as { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT =
  true;

beforeEach(() => {
  vi.stubGlobal("matchMedia", () => ({
    addEventListener: vi.fn(),
    matches: false,
    removeEventListener: vi.fn(),
  }));
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
});

afterEach(async () => {
  await act(async () => root.unmount());
  container.remove();
  vi.unstubAllGlobals();
});

const renderSidebar = ({ actionsDisabled = false } = {}) => {
  const onGitChanges = vi.fn();
  const onGitWorkingTree = vi.fn();
  const onOpenChange = vi.fn();
  const openerRef = { current: document.createElement("button") };
  document.body.append(openerRef.current);

  root.render(
    createElement(MobileWorkspaceSidebar, {
      actionsDisabled,
      onGitChanges,
      onGitWorkingTree,
      onNotifications: vi.fn(),
      onOpenChange,
      onResetFontSize: vi.fn(),
      onSelectSession: vi.fn(),
      onSettings: vi.fn(),
      open: true,
      openerRef,
      selectedSessionId: null,
      sessions: [],
    }),
  );
  return { onGitChanges, onGitWorkingTree, onOpenChange, openerRef };
};

testCases(
  "opens the requested Git comparison and dismisses the sidebar",
  async () => {
    let callbacks!: ReturnType<typeof renderSidebar>;
    await act(async () => {
      callbacks = renderSidebar();
    });
    const { onGitChanges, onGitWorkingTree, onOpenChange, openerRef } =
      callbacks;
    const branchDiff = Array.from(document.querySelectorAll("button")).find(
      (button) => button.textContent?.includes("Changes vs origin/main"),
    );
    const localChanges = Array.from(document.querySelectorAll("button")).find(
      (button) => button.textContent?.includes("Local changes"),
    );

    await act(async () => branchDiff?.click());
    expect(onGitWorkingTree).toHaveBeenCalledOnce();
    expect(onGitChanges).not.toHaveBeenCalled();
    expect(onOpenChange).toHaveBeenLastCalledWith(false);

    await act(async () => localChanges?.click());
    expect(onGitChanges).toHaveBeenCalledOnce();
    expect(onOpenChange).toHaveBeenLastCalledWith(false);
    openerRef.current.remove();
  },
);

testCases("disables Git actions without an active pane", async () => {
  let callbacks!: ReturnType<typeof renderSidebar>;
  await act(async () => {
    callbacks = renderSidebar({ actionsDisabled: true });
  });
  const { onGitChanges, onGitWorkingTree, openerRef } = callbacks;
  const gitActions = Array.from(document.querySelectorAll("button")).filter(
    (button) =>
      button.textContent?.includes("Changes vs origin/main") ||
      button.textContent?.includes("Local changes"),
  );

  expect(gitActions).toHaveLength(2);
  expect(gitActions.every((button) => button.disabled)).toBe(true);
  await act(async () => gitActions.forEach((button) => button.click()));
  expect(onGitWorkingTree).not.toHaveBeenCalled();
  expect(onGitChanges).not.toHaveBeenCalled();
  openerRef.current.remove();
});
