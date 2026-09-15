import { z } from "zod";

export const notificationChannels = ["all", "agent", "github"] as const;
export type NotificationChannel = (typeof notificationChannels)[number];

export const isNotificationChannel = (
  channel: string | undefined,
): channel is NotificationChannel =>
  Boolean(
    channel && notificationChannels.includes(channel as NotificationChannel),
  );

const notificationOverlaySchema = z
  .object({
    channel: z.enum(notificationChannels),
    id: z.string().min(1).optional(),
  })
  .strict();

export type NotificationOverlay = z.infer<typeof notificationOverlaySchema>;

export const notificationSearchSchema = z.object({
  notification: notificationOverlaySchema.optional().catch(undefined),
});

export const notificationFromSearch = (search: unknown) =>
  notificationSearchSchema.parse(search).notification;

export const notificationPath = (channel: NotificationChannel, id?: string) =>
  id
    ? `/notifications/${channel}/${encodeURIComponent(id)}`
    : `/notifications/${channel}`;


