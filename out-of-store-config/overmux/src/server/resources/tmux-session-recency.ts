import { mkdirSync, watch } from "node:fs";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, dirname, join } from "node:path";
import {
  defineResourceContract,
  noInputSchema,
  type HandlerContext,
  type SubscriptionResourceDefinition,
} from "overmux";
import type { TmuxBackend } from "@overmux/tmux/server";
import { z } from "zod";

const tmuxSessionRecencySchema = z
  .object({
    recordedAtByName: z.record(z.string(), z.number()),
    liveById: z.record(
      z.string(),
      z.object({ lastAttached: z.number(), activity: z.number() }).strict(),
    ),
  })
  .strict();

export type TmuxSessionRecency = z.infer<typeof tmuxSessionRecencySchema>;
type RecencyBackend = Pick<TmuxBackend, "run" | "subscribeNotifications">;
type RecencySource = {
  backend: RecencyBackend;
  recencyFile: string;
  watchError?: Error;
};

const separator = "\u001f";
const sessionFormat = [
  "#{session_id}",
  "#{?session_last_attached,#{session_last_attached},0}",
  "#{session_activity}",
].join(separator);

const timestamp = (value = "") => {
  const parsed = Number.parseFloat(value);
  return Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
};

export const parseTmuxSessionRecency = (content: string) => {
  const recordedAtByName = new Map<string, number>();
  content.split("\n").forEach((line) => {
    const [recordedAt, name] = line.split("\t");
    if (name && !recordedAtByName.has(name)) {
      recordedAtByName.set(name, timestamp(recordedAt));
    }
  });
  return Object.fromEntries(recordedAtByName);
};

const parseLiveRecency = (content: string): TmuxSessionRecency["liveById"] =>
  Object.fromEntries(
    content.split("\n").flatMap((line) => {
      const [id = "", lastAttached, activity] = line.split(separator);
      return /^\$\d+$/.test(id)
        ? [
            [
              id,
              {
                lastAttached: timestamp(lastAttached),
                activity: timestamp(activity),
              },
            ],
          ]
        : [];
    }),
  );

const readRecencyFile = async (path: string) => {
  try {
    return await readFile(path, "utf8");
  } catch (cause) {
    if ((cause as NodeJS.ErrnoException).code === "ENOENT") {
      return "";
    }
    throw cause;
  }
};

const readTmuxSessionRecency = async (
  source: RecencySource,
  { signal }: HandlerContext,
): Promise<TmuxSessionRecency> => {
  if (source.watchError) {
    throw source.watchError;
  }
  const [content, live] = await Promise.all([
    readRecencyFile(source.recencyFile),
    source.backend.run(["list-sessions", "-F", sessionFormat], signal),
  ]);
  signal.throwIfAborted();
  return {
    recordedAtByName: parseTmuxSessionRecency(content),
    liveById: parseLiveRecency(live),
  };
};

const subscribeTmuxSessionRecency = (
  source: RecencySource,
  invalidate: () => void,
  { signal }: HandlerContext,
) => {
  if (signal.aborted) {
    return () => undefined;
  }
  mkdirSync(dirname(source.recencyFile), { recursive: true });
  let disposed = false;
  let timer: NodeJS.Timeout | undefined;
  const schedule = () => {
    if (disposed || timer) {
      return;
    }
    timer = setTimeout(() => {
      timer = undefined;
      invalidate();
    }, 10);
    timer.unref();
  };
  // The hook replaces the file, so watch its directory rather than its inode.
  const watcher = watch(dirname(source.recencyFile), (_event, filename) => {
    if (filename === null || filename === basename(source.recencyFile)) {
      schedule();
    }
  });
  source.watchError = undefined;
  watcher.on("error", (cause) => {
    source.watchError = cause;
    watcher.close();
    schedule();
  });
  let unsubscribeBackend: (() => void) | undefined;
  const dispose = () => {
    if (disposed) {
      return;
    }
    disposed = true;
    signal.removeEventListener("abort", dispose);
    if (timer) {
      clearTimeout(timer);
    }
    watcher.close();
    unsubscribeBackend?.();
  };
  try {
    unsubscribeBackend = source.backend.subscribeNotifications(schedule);
  } catch (cause) {
    dispose();
    throw cause;
  }
  signal.addEventListener("abort", dispose, { once: true });
  return dispose;
};

export const tmuxSessionRecencyResource = ({
  backend,
  recencyFile = join(
    process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"),
    "tmux",
    "session-recency.tsv",
  ),
}: {
  backend: RecencyBackend;
  recencyFile?: string;
}): SubscriptionResourceDefinition<
  typeof noInputSchema,
  typeof tmuxSessionRecencySchema
> => {
  const source: RecencySource = { backend, recencyFile };
  return {
    contract: defineResourceContract({
      input: noInputSchema,
      output: tmuxSessionRecencySchema,
    }),
    kind: "subscription",
    read: (_input, context) => readTmuxSessionRecency(source, context),
    subscribe: (_input, invalidate, context) =>
      subscribeTmuxSessionRecency(source, invalidate, context),
  };
};
