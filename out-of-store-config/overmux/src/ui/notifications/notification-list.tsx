import { useEffect, useId, useMemo, useRef, useState } from "react";

import type { StoredNotification } from "../../zod-schemas";
import { localDateTime } from "../utils/date-time";
import type { NavigationArea } from "./navigation-area";
import { notificationTime } from "./notification-time";
import { toPlainTextPreview } from "./plain-text-preview";
import type { NotificationChannel } from "./routing";

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
}: NotificationListItemProps) => {
  const { label, time } = notificationTime(item.sentAt, now);

  return (
    <div
      aria-selected={selected}
      className="flex w-full cursor-pointer flex-col gap-1 border-b px-4 py-3 text-left hover:bg-panel-muted aria-selected:bg-panel-muted aria-selected:font-semibold"
      id={id}
      onClick={() => onSelect(item.id)}
      role="option"
    >
      <span className="flex items-start justify-between gap-3">
        <span className="min-w-0 truncate font-medium">{item.title}</span>
        <time
          className="flex shrink-0 flex-col items-end gap-x-1 whitespace-nowrap text-xs text-foreground/55 @min-[28rem]:flex-row"
          dateTime={item.sentAt}
          title={localDateTime(item.sentAt)}
        >
          <span>{label}</span>
          {time ? (
            <>
              {" "}
              <span>{time}</span>
            </>
          ) : null}
        </time>
      </span>
      <span className="line-clamp-2 text-sm text-foreground/65">
        {item.preview}
      </span>
    </div>
  );
};

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
        "@container min-h-0 flex-col border-r",
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
