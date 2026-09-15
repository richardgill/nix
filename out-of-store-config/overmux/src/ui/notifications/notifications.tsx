import { useParams, useRouter } from "@tanstack/react-router";
import { ArrowLeft } from "lucide-react";
import { useEffect, useMemo, useRef, useState, type KeyboardEvent } from "react";

import { useResource } from "../utils/overmux-hooks";
import { FullscreenDialog } from "../components/fullscreen-dialog";
import { workspaceNavigationHash } from "../utils/router-history";
import { DialogTitle } from "../shadcn/dialog";
import { useRouteState } from "../utils/use-route-state";
import { NotificationChannels } from "./notification-channels";
import { NotificationDetail } from "./notification-detail";
import { NotificationList } from "./notification-list";
import type { NavigationArea } from "./navigation-area";
import {
  isNotificationChannel,
  notificationChannels,
  notificationPath,
  type NotificationOverlay,
} from "./routing";

const notificationVisibleLocation = (
  notification: NotificationOverlay | undefined,
) =>
  notification
    ? { to: notificationPath(notification.channel, notification.id) }
    : undefined;

type NotificationSetter = (
  selection: NotificationOverlay | undefined,
  options?: { historyMode?: "push" | "replace" },
) => Promise<void>;

const NotificationsDialog = ({
  notification,
  onCloseAutoFocus,
  setNotification,
}: {
  notification: NotificationOverlay;
  onCloseAutoFocus?: () => void;
  setNotification: NotificationSetter;
}) => {
  const [activeArea, setActiveArea] = useState<NavigationArea>(
    notification.id ? "detail" : "list",
  );
  const localRouteUpdate = useRef(true);
  const items = useResource({ id: "notifications", input: { limit: 500 } });
  const visible = useMemo(() => {
    const notifications = items.data?.items ?? [];
    return notification.channel === "all"
      ? notifications
      : notifications.filter((item) => item.topic === notification.channel);
  }, [items.data?.items, notification.channel]);
  const selectedIndex = notification.id
    ? visible.findIndex((item) => item.id === notification.id)
    : 0;
  const selected = visible[selectedIndex];
  const totals = items.data?.totals ?? { agent: 0, all: 0, github: 0 };

  // Back/Forward chooses the panel from the URL; local selection changes keep the current panel.
  useEffect(() => {
    if (!localRouteUpdate.current)
      setActiveArea(notification.id ? "detail" : "list");
    localRouteUpdate.current = false;
  }, [notification.channel, notification.id]);

  const navigate = (
    next: NotificationOverlay,
    historyMode: "push" | "replace" = "push",
  ) => {
    localRouteUpdate.current =
      next.channel !== notification.channel || next.id !== notification.id;
    void setNotification(next, { historyMode });
  };
  const selectAdjacent = (offset: number) => {
    const lastIndex = visible.length - 1;
    const initialIndex = offset > 0 ? 0 : lastIndex;
    const nextIndex = selectedIndex === -1
      ? initialIndex
      : selectedIndex + offset;
    const index = Math.max(0, Math.min(lastIndex, nextIndex));
    const item = visible[index];
    if (item)
      navigate({ channel: notification.channel, id: item.id }, "replace");
  };
  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    const key = event.key === "Tab"
      ? (event.shiftKey ? "ArrowUp" : "ArrowDown")
      : event.key;
    if (key === "Enter") {
      event.preventDefault();
      event.stopPropagation();
      if (selected?.link) window.location.assign(selected.link);
      return;
    }
    if (!key.startsWith("Arrow")) return;

    event.preventDefault();
    event.stopPropagation();
    if (key === "ArrowUp" || key === "ArrowDown") {
      if (activeArea !== "channels") {
        selectAdjacent(key === "ArrowUp" ? -1 : 1);
        return;
      }
      const channelIndex = notificationChannels.indexOf(notification.channel);
      const offset = key === "ArrowUp" ? -1 : 1;
      const channel =
        notificationChannels[
          Math.max(
            0,
            Math.min(notificationChannels.length - 1, channelIndex + offset),
          )
        ];
      if (channel) navigate({ channel }, "replace");
      return;
    }
    if (key === "ArrowLeft") {
      if (activeArea === "detail") setActiveArea("list");
      else if (activeArea === "list") setActiveArea("channels");
      return;
    }
    if (activeArea === "channels" || activeArea === "list") {
      const item = selected ?? visible[0];
      if (!item) return;
      setActiveArea(activeArea === "channels" ? "list" : "detail");
      if (notification.id !== item.id)
        navigate({ channel: notification.channel, id: item.id }, "replace");
    }
  };
  // Clear notification URL state to dismiss the modal and reveal the underlying tmux URL.
  const close = () => void setNotification(undefined);
  const status =
    items.status === "pending" ? (
      <section className="col-span-full grid place-items-center p-4 text-foreground/60">
        Loading notifications…
      </section>
    ) : items.status === "error" ? (
      <section
        className="col-span-full grid place-items-center p-4 text-[var(--om-color-danger)]"
        role="alert"
      >
        {items.error.message}
      </section>
    ) : undefined;

  return (
    <FullscreenDialog
      onClose={close}
      onCloseAutoFocus={onCloseAutoFocus}
      onKeyDown={handleKeyDown}
      open
    >
      <main className="flex min-h-0 flex-1 flex-col bg-background text-foreground">
        <header className="flex shrink-0 items-center gap-2 border-b px-4 py-3 pr-24">
          {activeArea === "detail" ? (
            <button
              aria-label="Back to notifications"
              className="-my-2 -ml-2 flex size-10 shrink-0 items-center justify-center rounded hover:bg-panel-muted md:hidden"
              onClick={() => setActiveArea("list")}
              type="button"
            >
              <ArrowLeft aria-hidden="true" className="size-5" />
            </button>
          ) : null}
          <DialogTitle asChild>
            <h1 className="font-semibold">Notifications</h1>
          </DialogTitle>
        </header>
        <div className="grid min-h-0 flex-1 grid-cols-1 grid-rows-1 md:grid-cols-[13rem_minmax(18rem,0.8fr)_minmax(0,1.5fr)]">
          {status ?? (
            <>
              <NotificationChannels
                activeArea={activeArea}
                notification={notification}
                onNavigationArea={setActiveArea}
                onSelect={(channel) => {
                  setActiveArea("list");
                  navigate({ channel });
                }}
                totals={totals}
              />
              <NotificationList
                activeArea={activeArea}
                channel={notification.channel}
                items={visible}
                selectedId={selected?.id}
                onNavigationArea={setActiveArea}
                onSelect={(id) => {
                  setActiveArea("detail");
                  navigate({ channel: notification.channel, id });
                }}
              />
              <NotificationDetail
                activeArea={activeArea}
                notification={notification}
                onBack={() => setActiveArea("list")}
                onNavigationArea={setActiveArea}
                selected={selected}
              />
            </>
          )}
        </div>
      </main>
    </FullscreenDialog>
  );
};

export const NotificationsRoute = ({
  onCloseAutoFocus,
}: {
  onCloseAutoFocus?: () => void;
}) => {
  // Internal: /tmux/1/2/3?notification={"channel":"agent","id":"42"} (URL-encoded)
  // Visible:  /notifications/agent/42 - tmux stays mounted behind the modal.
  const [notification, setNotification] = useRouteState({
    getVisibleLocation: notificationVisibleLocation,
    historyMode: "push",
    routeId: "/tmux",
    searchParam: "notification",
  });

  return notification ? (
    <NotificationsDialog
      notification={notification}
      onCloseAutoFocus={onCloseAutoFocus}
      setNotification={setNotification}
    />
  ) : null;
};

export const NotificationsRedirectRoute = () => {
  const router = useRouter();
  const params = useParams({ strict: false });
  const rawChannel =
    typeof params.channel === "string" ? params.channel : undefined;
  const id = typeof params.id === "string" ? params.id : undefined;
  const channel = isNotificationChannel(rawChannel) ? rawChannel : "all";

  useEffect(() => {
    void router.navigate({
      mask: { to: notificationPath(channel, id) },
      replace: true,
      search: {
        notification: { channel, ...(id ? { id } : {}) },
      },
      to: "/tmux",
    });
  }, [channel, id, router]);
  return null;
};

export const openNotifications = (router: ReturnType<typeof useRouter>) =>
  router.navigate({
    hash: workspaceNavigationHash(router, { masked: true }),
    mask: { to: notificationPath("all") },
    search: (search) => ({
      ...search,
      notification: { channel: "all" as const },
    }),
    to: ".",
  });
