// Tmux actions retain the selected pane as their explicit context.
// Tmux failures intentionally propagate through the operation boundary.
// Pane cleanup uses the user's graceful-kill script rather than tmux kill-pane.
import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { defineOperation } from "overmux";
import type { TmuxBackend } from "@overmux/tmux/server";
import { z } from "zod";

const execFileAsync = promisify(execFile);
type ExecuteFile = (file: string, args: string[]) => Promise<unknown>;
const paneInput = z.object({ paneId: z.string() }).strict();

export const createPiTmuxWindow = async ({
  backend,
  paneId,
  signal,
}: {
  backend: TmuxBackend;
  paneId: string;
  signal: AbortSignal;
}) => {
  const path = (
    await backend.run(
      ["display-message", "-p", "-t", paneId, "#{pane_current_path}"],
      signal,
    )
  ).trim();
  const sessionId = (
    await backend.run(
      ["display-message", "-p", "-t", paneId, "#{session_id}"],
      signal,
    )
  ).trim();
  const windowId = (
    await backend.run(
      ["new-window", "-P", "-F", "#{window_id}", "-c", path, "-t", sessionId],
      signal,
    )
  ).trim();
  await backend.run(["send-keys", "-t", windowId, "pi", "Enter"], signal);
};

export const killTmuxPane = async ({
  executeFile = execFileAsync as ExecuteFile,
  paneId,
}: {
  executeFile?: ExecuteFile;
  paneId: string;
}) => {
  await executeFile(join(homedir(), "Scripts", "tmux-kill-pane"), [paneId]);
};

export const tmuxOperationHandlers = ({
  backend,
}: {
  backend: TmuxBackend;
}) => ({
  createPiTmuxWindow: defineOperation({
    input: paneInput,
    handle: ({ paneId }, { signal }) =>
      createPiTmuxWindow({ backend, paneId, signal }),
  }),
  killTmuxPane: defineOperation({
    input: paneInput,
    handle: ({ paneId }) => killTmuxPane({ paneId }),
  }),
});
