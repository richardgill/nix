import { randomUUID } from "node:crypto";
import { join } from "node:path";
import { createJsonlStore } from "@overmux/jsonl-store/server";
import { defineOperation, defineResourceContract } from "overmux";
import { getOvermuxPaths } from "overmux/server";

import {
  notificationSchema,
  notificationsResourceInputSchema,
  notificationsResourceSchema,
  storedNotificationSchema,
} from "../zod-schemas";

const notificationStore = createJsonlStore({
  path: join(getOvermuxPaths().stateDir, "notifications.jsonl"),
  schema: storedNotificationSchema,
});
const subscribers = new Set<() => void>();

export const notificationOperation = defineOperation({
  input: notificationSchema,
  handle: async (input, { notifications }) => {
    const notification = {
      ...input,
      id: randomUUID(),
      sentAt: new Date().toISOString(),
    };
    await notificationStore.append(notification);
    subscribers.forEach((invalidate) => invalidate());
    await notifications.send({
      title: notification.title,
      body: notification.body,
      open: {
        link: notification.link ?? `/notifications/all/${notification.id}`,
      },
    });
  },
});

// Refresh open inboxes when notifications arrive, and remove callbacks when clients unsubscribe.
const subscribe = (
  _input: unknown,
  invalidate: () => void,
  { signal }: { signal: AbortSignal },
) => {
  if (signal.aborted) {
    return () => undefined;
  }
  const dispose = () => {
    signal.removeEventListener("abort", dispose);
    subscribers.delete(invalidate);
  };
  subscribers.add(invalidate);
  signal.addEventListener("abort", dispose, { once: true });
  return dispose;
};

export const notificationsResource = {
  contract: defineResourceContract({
    input: notificationsResourceInputSchema,
    output: notificationsResourceSchema,
  }),
  kind: "subscription" as const,
  read: async ({ limit }: { limit: number }) => {
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
  subscribe,
};
