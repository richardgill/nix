
import { join } from "node:path";
import { expect, test as testCases, vi } from "vitest";
import type { TmuxBackend } from "@overmux/tmux/server";

import { createPiTmuxWindow, killTmuxPane } from "./tmux-operations";

const backend = (run = vi.fn()) => ({ run }) as unknown as TmuxBackend;

testCases("creates and launches Pi in a pane's session and directory", async () => {
  const run = vi
    .fn()
    .mockResolvedValueOnce("/work/project\n")
    .mockResolvedValueOnce("$1\n")
    .mockResolvedValueOnce("@3\n")
    .mockResolvedValueOnce("");
  await createPiTmuxWindow({
    backend: backend(run),
    paneId: "%2",
    signal: new AbortController().signal,
  });

  expect(run.mock.calls.map(([args]) => args)).toEqual([
    ["display-message", "-p", "-t", "%2", "#{pane_current_path}"],
    ["display-message", "-p", "-t", "%2", "#{session_id}"],
    ["new-window", "-P", "-F", "#{window_id}", "-c", "/work/project", "-t", "$1"],
    ["send-keys", "-t", "@3", "pi", "Enter"],
  ]);
});

testCases("runs the graceful pane-kill script with the pane ID argument", async () => {
  const executeFile = vi.fn().mockResolvedValue(undefined);
  await killTmuxPane({ executeFile, paneId: "%2" });
  expect(executeFile).toHaveBeenCalledWith(
    join(homedir(), "Scripts", "tmux-kill-pane"),
    ["%2"],
  );
});

testCases("propagates tmux command failures", async () => {
  const run = vi.fn().mockRejectedValue(new Error("Pane disappeared"));
  await expect(
    createPiTmuxWindow({
      backend: backend(run),
      paneId: "%2",
      signal: new AbortController().signal,
    }),
  ).rejects.toThrow("Pane disappeared");
});
