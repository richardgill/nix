import { mkdtemp, mkdir, rename, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { HandlerContext } from "overmux";
import type { TmuxBackend } from "@overmux/tmux/server";
import { afterEach, expect, test as testCases, vi } from "vitest";
import {
  parseTmuxSessionRecency,
  tmuxSessionRecencyResource,
} from "./tmux-session-recency";

type NotificationListener = Parameters<
  TmuxBackend["subscribeNotifications"]
>[0];

const cleanups: (() => Promise<void> | void)[] = [];
afterEach(async () => {
  await Promise.all(cleanups.splice(0).map((cleanup) => cleanup()));
});

testCases.each([
  { label: "empty", content: "", expected: {} },
  {
    label: "malformed rows and numeric prefixes",
    content: "garbage\n9\t\t/path\nbad\tinvalid\n12seconds\tprefix\n\tempty\n",
    expected: { invalid: 0, prefix: 12, empty: 0 },
  },
  {
    label: "first occurrence wins without requiring a path",
    content: "20\twork\n99\twork\t/path\n5\tother\t/other\n",
    expected: { work: 20, other: 5 },
  },
  {
    label: "object-property names are ordinary names",
    content: "7\t__proto__\n8\tconstructor\n",
    expected: JSON.parse('{"__proto__":7,"constructor":8}'),
  },
])("parses $label", ({ content, expected }) => {
  expect(parseTmuxSessionRecency(content)).toEqual(expected);
});

const fixture = async () => {
  const directory = await mkdtemp(join(tmpdir(), "tmux-session-recency-"));
  const controller = new AbortController();
  cleanups.push(
    () => controller.abort(),
    () => rm(directory, { recursive: true, force: true }),
  );
  const recencyFile = join(directory, "tmux", "session-recency.tsv");
  const listeners = new Set<NotificationListener>();
  const unsubscribe = vi.fn();
  const backend = {
    run: vi.fn(async () => "$0\u001f10\u001f20\n$1\u001f0\u001f2\n"),
    subscribeNotifications: vi.fn((listener: NotificationListener) => {
      listeners.add(listener);
      return () => {
        listeners.delete(listener);
        unsubscribe();
      };
    }),
  };
  const context: HandlerContext = {
    signal: controller.signal,
    invalidate: vi.fn(),
    instance: {
      getInstanceId: () => "test",
      getDeepLinkPrefix: () => "overmux://test",
    },
  };
  const resource = tmuxSessionRecencyResource({ backend, recencyFile });
  return {
    backend,
    context,
    controller,
    listeners,
    recencyFile,
    resource,
    unsubscribe,
  };
};

testCases(
  "missing file is empty and live tie-breakers use the shared backend",
  async () => {
    const { resource, backend, context } = await fixture();
    expect(await resource.read(undefined, context)).toEqual({
      recordedAtByName: {},
      liveById: {
        $0: { lastAttached: 10, activity: 20 },
        $1: { lastAttached: 0, activity: 2 },
      },
    });
    expect(backend.run).toHaveBeenCalledWith(
      ["list-sessions", "-F", expect.stringContaining("session_last_attached")],
      context.signal,
    );
  },
);

testCases("propagates file and backend read failures", async () => {
  const { resource, recencyFile, backend, context } = await fixture();
  await mkdir(recencyFile, { recursive: true });
  await expect(resource.read(undefined, context)).rejects.toMatchObject({
    code: "EISDIR",
  });
  await rm(recencyFile, { recursive: true });
  backend.run.mockRejectedValueOnce(new Error("tmux failed"));
  await expect(resource.read(undefined, context)).rejects.toThrow(
    "tmux failed",
  );
});

testCases(
  "invalidates after creation, replacement, removal and backend events; abort cleans up",
  async () => {
    const {
      resource,
      recencyFile,
      context,
      controller,
      backend,
      listeners,
      unsubscribe,
    } = await fixture();
    const invalidate = vi.fn();
    const dispose = resource.subscribe(undefined, invalidate, context);
    await writeFile(recencyFile, "30\tz\t/z\n");
    await vi.waitFor(() => expect(invalidate).toHaveBeenCalled());
    expect((await resource.read(undefined, context)).recordedAtByName).toEqual({
      z: 30,
    });
    invalidate.mockClear();
    await writeFile(`${recencyFile}.tmp`, "40\ta\t/a\n");
    await rename(`${recencyFile}.tmp`, recencyFile);
    await vi.waitFor(() => expect(invalidate).toHaveBeenCalled());
    expect((await resource.read(undefined, context)).recordedAtByName).toEqual({
      a: 40,
    });
    invalidate.mockClear();
    await rm(recencyFile);
    await vi.waitFor(() => expect(invalidate).toHaveBeenCalled());
    expect((await resource.read(undefined, context)).recordedAtByName).toEqual(
      {},
    );
    invalidate.mockClear();
    backend.run.mockResolvedValue("$0\u001f10\u001f20\n$1\u001f90\u001f2\n");
    listeners.forEach((listener) => listener({ type: "sessions-changed" }));
    await vi.waitFor(() => expect(invalidate).toHaveBeenCalledOnce());
    expect((await resource.read(undefined, context)).liveById.$1).toEqual({
      lastAttached: 90,
      activity: 2,
    });
    listeners.forEach((listener) => listener({ type: "sessions-changed" }));
    controller.abort();
    await dispose();
    invalidate.mockClear();
    await writeFile(recencyFile, "50\ta\t/a\n");
    await new Promise((resolve) => setTimeout(resolve, 40));
    expect(invalidate).not.toHaveBeenCalled();
    expect(listeners.size).toBe(0);
    expect(unsubscribe).toHaveBeenCalledOnce();
  },
);

testCases(
  "explicit disposal is idempotent and an aborted subscription opens nothing",
  async () => {
    const { resource, context, controller, backend, unsubscribe } =
      await fixture();
    const dispose = resource.subscribe(undefined, vi.fn(), context);
    await dispose();
    await dispose();
    controller.abort();
    await resource.subscribe(undefined, vi.fn(), context)();
    expect(backend.subscribeNotifications).toHaveBeenCalledOnce();
    expect(unsubscribe).toHaveBeenCalledOnce();
  },
);
