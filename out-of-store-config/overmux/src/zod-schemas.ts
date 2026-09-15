import { tmuxStateSchema } from "@overmux/tmux/shared";
import { notificationLinkSchema } from "overmux";
import { z } from "zod";

export const notificationSchema = z
  .object({
    body: z.string().max(4_096),
    link: notificationLinkSchema.optional(),
    title: z.string().min(1).max(4_096),
    topic: z.enum(["agent", "github"]),
  })
  .strict();

export const storedNotificationSchema = notificationSchema
  .extend({
    id: z.string().uuid(),
    sentAt: z.iso.datetime(),
  })
  .strict();

export const notificationsResourceInputSchema = z
  .object({ limit: z.number().int().min(1).max(500) })
  .strict();

export const notificationsResourceSchema = z
  .object({
    items: z.array(storedNotificationSchema),
    total: z.number().int().nonnegative(),
    totals: z
      .object({
        agent: z.number().int().nonnegative(),
        all: z.number().int().nonnegative(),
        github: z.number().int().nonnegative(),
      })
      .strict(),
  })
  .strict();

export const piPaneSessionsSchema = z.array(
  z
    .object({
      agentId: z.string().min(1),
      paneId: z.string().min(1),
    })
    .strict(),
);

export const workspaceStateSchema = z
  .object({
    agentByPaneId: z.record(
      z.string(),
      z.object({ agentId: z.string().min(1) }).strict(),
    ),
    hostname: z.string().min(1),
    tmux: tmuxStateSchema,
  })
  .strict();

const sessionPickerRevisionSchema = z.number().int().nonnegative();
const sessionPickerRefSchema = z
  .string()
  .min(1)
  .max(256)
  .regex(/^[^\s]+$/);

const tmuxSessionPickerEntrySchema = z
  .object({
    actions: z.array(
      z.enum(["clear", "connect", "create", "kill", "quarantine", "revive"]),
    ),
    label: z.string().min(1).max(512),
    pathDisplay: z.string().min(1).max(512).optional(),
    ref: sessionPickerRefSchema,
    sessionId: z.string().min(1).optional(),
    state: z.enum(["active", "directory", "inactive", "quarantined"]),
  })
  .strict();

export const tmuxSessionPickerSchema = z
  .object({
    entries: z.array(tmuxSessionPickerEntrySchema),
    revision: sessionPickerRevisionSchema,
  })
  .strict();

export const tmuxSessionVisibilitySchema = z
  .object({
    sessionIds: z.array(z.string().regex(/^\$\d+$/)),
  })
  .strict();

export const tmuxSessionPickerActionInputSchema = z
  .object({
    ref: sessionPickerRefSchema,
    revision: sessionPickerRevisionSchema,
  })
  .strict();

export const tmuxSessionPickerActionResultSchema = z.discriminatedUnion(
  "outcome",
  [
    z
      .object({
        outcome: z.literal("success"),
        revision: sessionPickerRevisionSchema,
        sessionId: z.string().min(1).optional(),
      })
      .strict(),
    z
      .object({
        outcome: z.literal("stale"),
        revision: sessionPickerRevisionSchema,
      })
      .strict(),
    z
      .object({
        message: z.string().min(1),
        outcome: z.literal("error"),
        revision: sessionPickerRevisionSchema,
      })
      .strict(),
  ],
);

export type StoredNotification = z.infer<typeof storedNotificationSchema>;
export type TmuxSessionPicker = z.infer<typeof tmuxSessionPickerSchema>;
export type TmuxSessionPickerEntry = z.infer<
  typeof tmuxSessionPickerEntrySchema
>;
