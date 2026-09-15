import { execFile } from "node:child_process";
import { watch } from "node:fs";
import { hostname } from "node:os";
import { basename, dirname, join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { promisify } from "node:util";

import { defineOperation, defineOvermuxServer } from "overmux";
import { getOvermuxPaths } from "overmux/server";
import {
  defineGitRepositories,
  gitOperationHandlers,
  gitSourceControlResource,
} from "@overmux/git/server";
import { createJsonlStore } from "@overmux/jsonl-store/server";
import {
  createPiSessionStatusSource,
  definePiAgents,
  piOperationHandlers,
  piConversationStream,
} from "@overmux/pi/server";
import { defineResourceContract, noInputSchema } from "overmux";
import { z } from "zod";

import {
  notificationSchema,
  notificationsResourceInputSchema,
  notificationsResourceSchema,
  piPaneSessionsSchema,
  tmuxSessionPickerActionInputSchema,
  tmuxSessionPickerActionResultSchema,
  tmuxSessionPickerSchema,
  storedNotificationSchema,
  tmuxSessionVisibilitySchema,
  workspaceStateSchema,
} from "../zod-schemas";
import {
  createTmuxSessionPicker,
  createTmuxSessionVisibility,
} from "./tmux-session-picker";
import {
  tmuxOperations,
  tmuxBackend,
  tmuxState,
  tmuxTerminal,
} from "./tmux";

const execFileAsync = promisify(execFile);
const overmuxPaths = getOvermuxPaths();
const gitBaseCommand =
  "/home/rich/code/nix-private/flake/modules/home-manager/dot-files/Scripts/git-diff-base-ref";
const liveEventsDir = join(overmuxPaths.stateDir, "pi", "events");
const notificationStore = createJsonlStore({
  path: join(overmuxPaths.stateDir, "notifications.jsonl"),
  schema: storedNotificationSchema,
});
const serviceHostname = hostname();
const tmuxStateDir = "/home/rich/.local/state/tmux";

const notificationSubscribers = new Set<() => void>();
const piSessionStatuses = createPiSessionStatusSource({
  rootDir: liveEventsDir,
});

const subscribeToNotifications = (
  invalidate: () => void,
  { signal }: { signal: AbortSignal },
) => {
  if (signal.aborted) {
    return () => undefined;
  }
  const dispose = () => {
    signal.removeEventListener("abort", dispose);
    notificationSubscribers.delete(invalidate);
  };
  notificationSubscribers.add(invalidate);
  signal.addEventListener("abort", dispose, { once: true });
  return dispose;
};

const createEventDrivenSubscription = ({
  files,
  refresh,
}: {
  files: string[];
  refresh: (signal: AbortSignal) => Promise<boolean>;
}) => {
  const subscribers = new Set<() => void>();
  const filesByDirectory = new Map<string, Set<string>>();
  let controller: AbortController | undefined;
  let refreshTimer: ReturnType<typeof setTimeout> | undefined;
  let unsubscribeTmux: (() => void) | undefined;
  let watchers: ReturnType<typeof watch>[] = [];

  files.forEach((file) => {
    const directory = dirname(file);
    const names = filesByDirectory.get(directory) ?? new Set<string>();
    names.add(basename(file));
    filesByDirectory.set(directory, names);
  });

  const refreshAndInvalidate = () => {
    const activeController = controller;
    if (
      !activeController ||
      activeController.signal.aborted ||
      !subscribers.size
    ) {
      return;
    }
    void refresh(activeController.signal)
      .then((changed) => {
        if (changed && controller === activeController) {
          subscribers.forEach((invalidate) => invalidate());
        }
      })
      .catch(() => undefined);
  };
  const scheduleRefresh = () => {
    if (!controller || controller.signal.aborted || !subscribers.size) {
      return;
    }
    if (refreshTimer) {
      clearTimeout(refreshTimer);
    }
    refreshTimer = setTimeout(() => {
      refreshTimer = undefined;
      refreshAndInvalidate();
    }, 10);
    refreshTimer.unref();
  };
  const start = () => {
    controller = new AbortController();
    unsubscribeTmux = tmuxBackend.subscribe(scheduleRefresh);
    watchers = [...filesByDirectory].flatMap(([directory, names]) => {
      try {
        const watcher = watch(directory, (_eventType, fileName) => {
          if (!fileName || names.has(fileName.toString())) {
            scheduleRefresh();
          }
        });
        watcher.on("error", () => undefined);
        return [watcher];
      } catch {
        return [];
      }
    });
  };
  const stop = () => {
    if (refreshTimer) {
      clearTimeout(refreshTimer);
      refreshTimer = undefined;
    }
    controller?.abort();
    controller = undefined;
    unsubscribeTmux?.();
    unsubscribeTmux = undefined;
    watchers.forEach((watcher) => watcher.close());
    watchers = [];
  };
  const subscribe = (
    invalidate: () => void,
    { signal }: { signal: AbortSignal },
  ) => {
    if (signal.aborted) {
      return () => undefined;
    }
    let disposed = false;
    const dispose = () => {
      if (disposed) {
        return;
      }
      disposed = true;
      signal.removeEventListener("abort", dispose);
      subscribers.delete(invalidate);
      if (!subscribers.size) {
        stop();
      }
    };
    subscribers.add(invalidate);
    if (subscribers.size === 1) {
      start();
    }
    signal.addEventListener("abort", dispose, { once: true });
    return dispose;
  };

  return subscribe;
};

const createWindowResultSchema = z.discriminatedUnion("outcome", [
  z.object({ outcome: z.literal("success"), windowId: z.string() }).strict(),
  z.object({ outcome: z.literal("not-found") }).strict(),
  z.object({ message: z.string(), outcome: z.literal("error") }).strict(),
]);
const createWindowOperation = defineOperation({
  input: z
    .object({
      launch: z.literal("pi").optional(),
      paneId: z.string().regex(/^%\d+$/),
    })
    .strict(),
  output: createWindowResultSchema,
  handle: async ({ launch, paneId }, { signal }) => {
    try {
      const path = (
        await tmuxBackend.run(
          ["display-message", "-p", "-t", paneId, "#{pane_current_path}"],
          signal,
        )
      ).trim();
      if (!path) {
        return { outcome: "not-found" as const };
      }
      const sessionId = (
        await tmuxBackend.run(
          ["display-message", "-p", "-t", paneId, "#{session_id}"],
          signal,
        )
      ).trim();
      if (!/^\$\d+$/.test(sessionId)) {
        return { outcome: "not-found" as const };
      }
      const windowId = (
        await tmuxBackend.run(
          [
            "new-window",
            "-P",
            "-F",
            "#{window_id}",
            "-c",
            path,
            "-t",
            sessionId,
          ],
          signal,
        )
      ).trim();
      if (!/^@\d+$/.test(windowId)) {
        throw new Error("Tmux did not return the created window reference");
      }
      if (launch) {
        await tmuxBackend.run(
          ["send-keys", "-t", windowId, launch, "Enter"],
          signal,
        );
      }
      return { outcome: "success" as const, windowId };
    } catch (cause) {
      return {
        message: cause instanceof Error ? cause.message : String(cause),
        outcome: "error" as const,
      };
    }
  },
});

const killTmuxPaneGracefully = async (paneId: string, signal?: AbortSignal) => {
  const pid = (
    await tmuxBackend.run(
      ["display-message", "-p", "-t", paneId, "#{pane_pid}"],
      signal,
    )
  ).trim();
  if (!/^\d+$/.test(pid)) {
    throw new Error(`Pane is no longer available: ${paneId}`);
  }
  const descendants = `children() { for child in $(pgrep -P "$1" 2>/dev/null); do children "$child"; printf '%s\\n' "$child"; done; }`;
  await tmuxBackend.run(
    [
      "run-shell",
      `${descendants}; pids=$(children ${pid}); test -z "$pids" || kill -TERM $pids 2>/dev/null || true`,
    ],
    signal,
  );
  await delay(300, undefined, { signal });
  const survivors = await tmuxBackend.run(
    [
      "run-shell",
      `${descendants}; pids=$(children ${pid}); test -z "$pids" || { printf '%s\\n' "$pids"; kill -KILL $pids 2>/dev/null || true; }`,
    ],
    signal,
  );
  await tmuxBackend.run(["kill-pane", "-t", paneId], signal);
  return { forced: Boolean(survivors.trim()) };
};

const killTmuxSessionGracefully = async (
  sessionId: string,
  signal?: AbortSignal,
) => {
  const panes = (
    await tmuxBackend.run(
      ["list-panes", "-t", sessionId, "-s", "-F", "#{pane_id}"],
      signal,
    )
  )
    .trim()
    .split("\n")
    .filter(Boolean);
  const results = await Promise.all(
    panes.map((paneId) => killTmuxPaneGracefully(paneId, signal)),
  );
  await tmuxBackend
    .run(["kill-session", "-t", sessionId], signal)
    .catch((cause) => {
      if (!results.length) {
        throw cause;
      }
    });
  return { forced: results.some(({ forced }) => forced) };
};

const piAgents = definePiAgents({
  liveEventsDir,
  sessions: {
    list: async () =>
      (await piSessionStatuses.list()).map(
        ({
          contextUsage,
          model,
          modelOptions,
          sessionFile,
          sessionId,
          thinkingLevel,
        }) => ({
          id: sessionId,
          sessionFile,
          sessionMetadata: { contextUsage, model, modelOptions, thinkingLevel },
        }),
      ),
    subscribe: piSessionStatuses.subscribe,
  },
});
const repositories = defineGitRepositories({
  allowedRoots: ["/home/rich/code"],
  baseResolver: async ({ root, signal }) => {
    const { stdout: baseOutput } = await execFileAsync(gitBaseCommand, [], {
      cwd: root,
      encoding: "utf8",
      signal,
    });
    const base = baseOutput.trim();
    if (!base) {
      throw new Error("Git base resolver returned no reference");
    }
    const { stdout } = await execFileAsync(
      "git",
      ["merge-base", "HEAD", base],
      {
        cwd: root,
        encoding: "utf8",
        signal,
      },
    );
    return stdout.trim();
  },
  watch: { debounceMs: 15 },
  permissions: {
    applyPatch: true,
    discard: true,
    stage: true,
    unstage: true,
  },
});
const runTmux = async (args: readonly string[], signal?: AbortSignal) => ({
  stderr: "",
  stdout: await tmuxBackend.run(args, signal),
});
const quarantineFile = `${tmuxStateDir}/worktree-pr-quarantine.tsv`;
const sessionVisibility = createTmuxSessionVisibility(
  { quarantineFile },
  { runTmux },
);
const subscribeToSessionVisibility = createEventDrivenSubscription({
  files: [quarantineFile],
  refresh: (signal) => sessionVisibility.refresh(signal),
});

const recencyFile = `${tmuxStateDir}/session-recency.tsv`;
const zoxideDatabaseFile = "/home/rich/.local/share/zoxide/db.zo";
const sessionPicker = createTmuxSessionPicker(
  {
    home: "/home/rich",
    quarantineCommand:
      "/home/rich/code/nix-private/flake/modules/home-manager/dot-files/Scripts/worktree-pr-autokill",
    quarantineFile,
    recencyFile,
  },
  {
    killSession: killTmuxSessionGracefully,
    refreshTmux: async () => {
      await tmuxBackend.refresh();
    },
    runTmux,
  },
);
const subscribeToSessionPicker = createEventDrivenSubscription({
  files: [quarantineFile, recencyFile, zoxideDatabaseFile],
  refresh: (signal) => sessionPicker.refresh(signal),
});

const notificationsContract = defineResourceContract({
  input: notificationsResourceInputSchema,
  output: notificationsResourceSchema,
});
const piPaneSessionsContract = defineResourceContract({
  input: noInputSchema,
  output: piPaneSessionsSchema,
});
const workspaceStateContract = defineResourceContract({
  input: noInputSchema,
  output: workspaceStateSchema,
});
const sessionPickerContract = defineResourceContract({
  input: noInputSchema,
  output: tmuxSessionPickerSchema,
});
const sessionVisibilityContract = defineResourceContract({
  input: noInputSchema,
  output: tmuxSessionVisibilitySchema,
});
const sessionPickerOperation = (
  action: "clear" | "connect" | "create" | "kill" | "quarantine" | "revive",
) =>
  defineOperation({
    input: tmuxSessionPickerActionInputSchema,
    output: tmuxSessionPickerActionResultSchema,
    handle: async ({ ref, revision }, { signal }) => {
      try {
        const result = await sessionPicker.action(
          action,
          revision,
          ref,
          signal,
        );
        await sessionPicker.refresh(signal);
        const nextRevision = sessionPicker.snapshot().revision;
        return result.outcome === "stale"
          ? { outcome: "stale" as const, revision: nextRevision }
          : {
              outcome: "success" as const,
              revision: nextRevision,
              ...(result.sessionId ? { sessionId: result.sessionId } : {}),
            };
      } catch (cause) {
        return {
          message: cause instanceof Error ? cause.message : String(cause),
          outcome: "error" as const,
          revision: sessionPicker.snapshot().revision,
        };
      }
    },
  });

export default defineOvermuxServer({
  operations: {
    ...tmuxOperations,
    ...piOperationHandlers({ agents: piAgents }),
    ...gitOperationHandlers({ repositories }),
    notification: defineOperation({
      input: notificationSchema,
      handle: async (notification, { notifications }) => {
        const id = crypto.randomUUID();
        await notificationStore.append({
          ...notification,
          id,
          sentAt: new Date().toISOString(),
        });
        notificationSubscribers.forEach((invalidate) => invalidate());
        await notifications.send({
          title: notification.title,
          body: notification.body,
          open: { link: notification.link ?? `/notifications/all/${id}` },
        });
      },
    }),
    createWindow: createWindowOperation,
    sessionPickerClear: sessionPickerOperation("clear"),
    sessionPickerConnect: sessionPickerOperation("connect"),
    sessionPickerCreate: sessionPickerOperation("create"),
    sessionPickerKill: sessionPickerOperation("kill"),
    sessionPickerQuarantine: sessionPickerOperation("quarantine"),
    sessionPickerRevive: sessionPickerOperation("revive"),
  },
  resources: {
    notifications: {
      contract: notificationsContract,
      kind: "subscription",
      read: async ({ limit }) => {
        const rows = await notificationStore.getAll();
        return {
          items: rows.slice(-limit).reverse(),
          total: rows.length,
          totals: {
            agent: rows.filter((row) => row.topic === "agent").length,
            all: rows.length,
            github: rows.filter((row) => row.topic === "github").length,
          },
        };
      },
      subscribe: (_input, invalidate, context) =>
        subscribeToNotifications(invalidate, context),
    },
    tmuxState,
    piPaneSessions: {
      contract: piPaneSessionsContract,
      kind: "subscription",
      read: async () =>
        (await piSessionStatuses.list()).flatMap(({ sessionId, tmuxPane }) =>
          tmuxPane ? [{ agentId: sessionId, paneId: tmuxPane }] : [],
        ),
      subscribe: (_input, invalidate, context) =>
        piSessionStatuses.subscribe(invalidate, context),
    },
    richardTmuxSessionPicker: {
      contract: sessionPickerContract,
      kind: "subscription",
      read: async (_input, { signal }) => {
        await sessionPicker.refresh(signal);
        return sessionPicker.snapshot();
      },
      subscribe: (_input, invalidate, context) =>
        subscribeToSessionPicker(invalidate, context),
    },
    richardTmuxSessionVisibility: {
      contract: sessionVisibilityContract,
      kind: "subscription",
      read: async (_input, { signal }) => {
        await sessionVisibility.initialize(signal);
        return sessionVisibility.snapshot();
      },
      subscribe: (_input, invalidate, context) =>
        subscribeToSessionVisibility(invalidate, context),
    },
    workspaceState: {
      combine: ({ piSessions, sessionVisibility: visibility, tmux }) => {
        const activeSessionIds = new Set(visibility.sessionIds);
        return {
          agentByPaneId: Object.fromEntries(
            piSessions.map(({ agentId, paneId }) => [paneId, { agentId }]),
          ),
          hostname: serviceHostname,
          tmux: {
            ...tmux,
            hierarchy: {
              sessions: tmux.hierarchy.sessions.filter(({ id }) =>
                activeSessionIds.has(id),
              ),
            },
          },
        };
      },
      contract: workspaceStateContract,
      dependencies: {
        piSessions: "piPaneSessions",
        sessionVisibility: "richardTmuxSessionVisibility",
        tmux: "tmuxState",
      },
      kind: "derived",
    },
    gitSourceControl: gitSourceControlResource({ repositories }),
  },
  streams: {
    piConversation: piConversationStream({
      agents: piAgents,
      maxEntries: 100,
    }),
    tmuxTerminal,
  },
});
