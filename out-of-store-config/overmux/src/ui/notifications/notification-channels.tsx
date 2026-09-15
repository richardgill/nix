import type { NavigationArea } from "./navigation-area";
import {
  notificationChannels,
  type NotificationChannel as NotificationChannelId,
  type NotificationOverlay,
} from "./routing";

type NotificationChannelsProps = {
  activeArea: NavigationArea;
  notification: NotificationOverlay;
  onNavigationArea: (area: NavigationArea) => void;
  onSelect: (channel: NotificationChannelId) => void;
  totals: Record<NotificationChannelId, number>;
};

type NotificationChannelProps = {
  channel: NotificationChannelId;
  count: number;
  onSelect: (channel: NotificationChannelId) => void;
  selected: boolean;
};

const NotificationChannel = ({
  channel,
  count,
  onSelect,
  selected,
}: NotificationChannelProps) => (
  <button
    aria-current={selected ? "page" : undefined}
    className="flex shrink-0 items-center justify-between gap-4 rounded px-3 py-2 text-left text-sm hover:bg-panel-muted aria-[current=page]:bg-panel-muted aria-[current=page]:font-semibold"
    onClick={() => onSelect(channel)}
    type="button"
  >
    <span className="capitalize">{channel}</span>
    <span className="text-foreground/55">{count}</span>
  </button>
);

export const NotificationChannels = ({
  activeArea,
  notification,
  onNavigationArea,
  onSelect,
  totals,
}: NotificationChannelsProps) => (
  <aside
    className={[
      "shrink-0 border-b p-2 md:min-h-0 md:block md:border-r md:border-b-0",
      activeArea === "channels"
        ? "block md:outline-2 md:-outline-offset-2 md:outline-accent"
        : "hidden",
    ].join(" ")}
    data-notification-area="channels"
    onFocusCapture={() => onNavigationArea("channels")}
    onPointerDown={() => onNavigationArea("channels")}
  >
    <nav
      aria-label="Notification channels"
      className="flex gap-1 overflow-x-auto md:flex-col"
    >
      {notificationChannels.map((channel) => (
        <NotificationChannel
          channel={channel}
          count={totals[channel]}
          key={channel}
          onSelect={onSelect}
          selected={notification.channel === channel}
        />
      ))}
    </nav>
  </aside>
);
