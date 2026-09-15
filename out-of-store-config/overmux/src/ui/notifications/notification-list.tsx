import { useEffect, useId, useMemo, useRef, useState } from "react";

import type { StoredNotification } from "../../zod-schemas";
import { localDateTime } from "../utils/date-time";
import type { NavigationArea } from "./navigation-area";
import { toPlainTextPreview } from "./plain-text-preview";
import type { NotificationChannel } from "./routing";

const sameDay = (left: Date, right: Date) =>
  left.getFullYear() === right.getFullYear() &&
  left.getMonth() === right.getMonth() &&
  left.getDate() === right.getDate();

const relativeTime = (timestamp: string, now: number) => {
  const sentAt = new Date(timestamp);
  const current = new Date(now);
  const elapsed = Math.max(0, now - sentAt.getTime());
  const minutes = Math.floor(elapsed / 60_000);
  if (minutes < 1) return "now";
  if (minutes < 60) return `${minutes}m`;
  if (sameDay(sentAt, current) && minutes < 6 * 60)
    return `${Math.floor(minutes / 60)}h`;
  if (sameDay(sentAt, current)) {
    return new Intl.DateTimeFormat(undefined, { timeStyle: "short" }).format(
      sentAt,
    );
  }
  const yesterday = new Date(now);
  yesterday.setDate(current.getDate() - 1);
  if (sameDay(sentAt, yesterday)) return "Yesterday";
  if (elapsed < 7 * 24 * 60 * 60_000) {
    return new Intl.DateTimeFormat(undefined, { weekday: "short" }).format(
      sentAt,
    );
  }
  return new Intl.DateTimeFormat(undefined, { dateStyle: "medium" }).format(
    sentAt,
  );
};

const useCurrentMinute = () => {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 60_000);
    return () => window.clearInterval(timer);
  }, []);
  return now;
};

type NotificationListProps = {
  activeArea: NavigationArea;
  channel: NotificationChannel;
  items: StoredNotification[];
  selectedId?: string;
  onNavigationArea: (area: NavigationArea) => void;
  onSelect: (id: string) => void;
};

type NotificationListItemProps = {
  id: string;
  item: StoredNotification & { preview: string };
  now: number;
  onSelect: (id: string) => void;
  selected: boolean;
};

const NotificationListItem = ({
  id,
  item,
  now,
  onSelect,
  selected,
}: NotificationListItemProps) => (
  <div
    aria-selected={selected}
    className="flex w-full cursor-pointer flex-col gap-1 border-b px-4 py-3 text-left hover:bg-panel-muted aria-selected:bg-panel-muted aria-selected:font-semibold"
    id={id}
    onClick={() => onSelect(item.id)}
    role="option"
  >
    <span className="flex items-start justify-between gap-3">
      <span className="line-clamp-1 font-medium">{item.title}</span>
      <time
        className="shrink-0 text-xs text-foreground/55"
        dateTime={item.sentAt}
        title={localDateTime(item.sentAt)}
      >
        {relativeTime(item.sentAt, now)}
      </time>
    </span>
    <span className="line-clamp-2 text-sm text-foreground/65">{item.preview}</span>
  </div>
);

export const NotificationList = ({
  activeArea,
  channel,
  items,
  selectedId,
  onNavigationArea,
  onSelect,
}: NotificationListProps) => {
  const listId = useId();
  const listRef = useRef<HTMLDivElement>(null);
  const now = useCurrentMinute();
  const previews = useMemo(
    () =>
      items.map((item) => ({
        ...item,
        preview: toPlainTextPreview(item.body),
      })),
    [items],
  );
  // scroll item into view as selected id changes
  useEffect(() => {
    listRef.current
      ?.querySelector<HTMLElement>("[role='option'][aria-selected='true']")
      ?.scrollIntoView({ block: "nearest" });
  }, [activeArea, selectedId]);

  return (
    <section
      className={[
        "min-h-0 flex-col border-r",
        activeArea === "list"
          ? "flex md:outline-2 md:-outline-offset-2 md:outline-accent"
          : "hidden md:flex",
      ].join(" ")}
      data-notification-area="list"
      onFocusCapture={() => onNavigationArea("list")}
      onPointerDown={() => onNavigationArea("list")}
    >
      <header className="hidden shrink-0 items-center justify-between border-b px-4 py-3 md:flex">
        <h2 className="font-medium capitalize">{channel}</h2>
        <span className="text-sm text-foreground/55">{items.length} shown</span>
      </header>
      <div
        aria-activedescendant={
          selectedId ? `${listId}-${selectedId}` : undefined
        }
        aria-label="Notifications"
        className="min-h-0 overflow-y-auto"
        ref={listRef}
        role="listbox"
        tabIndex={0}
      >
        {!items.length ? (
          <p className="p-4 text-sm text-foreground/60">
            No notifications in this channel.
          </p>
        ) : null}
        {previews.map((item) => (
          <NotificationListItem
            id={`${listId}-${item.id}`}
            item={item}
            key={item.id}
            now={now}
            onSelect={onSelect}
            selected={selectedId === item.id}
          />
        ))}
      </div>
    </section>
  );
};
