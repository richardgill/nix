import type { StoredNotification } from "../../zod-schemas";
import { Kbd } from "../shadcn/kbd";
import { localDateTime } from "../utils/date-time";
import type { NavigationArea } from "./navigation-area";
import { NotificationMarkdown } from "./markdown";
import type { NotificationOverlay } from "./routing";

type NotificationDetailProps = {
  activeArea: NavigationArea;
  notification: NotificationOverlay;
  onBack: () => void;
  onNavigationArea: (area: NavigationArea) => void;
  selected?: StoredNotification;
};

export const NotificationDetail = ({
  activeArea,
  notification,
  onBack,
  onNavigationArea,
  selected,
}: NotificationDetailProps) => (
  <section
    className={[
      "min-h-0 flex-col",
      activeArea === "detail"
        ? "flex md:outline-2 md:-outline-offset-2 md:outline-accent"
        : "hidden md:flex",
    ].join(" ")}
    data-notification-area="detail"
    onFocusCapture={() => onNavigationArea("detail")}
    onPointerDown={() => onNavigationArea("detail")}
  >
    {selected ? (
      <>
        <header className="flex shrink-0 items-start justify-between gap-4 border-b px-4 py-3">
          <div className="min-w-0">
            <p className="text-xs font-medium uppercase tracking-wide text-foreground/55">
              {selected.topic}
            </p>
            <h2 className="mt-1 text-lg font-semibold">{selected.title}</h2>
            <time
              className="mt-2 block text-sm text-foreground/60"
              dateTime={selected.sentAt}
            >
              {localDateTime(selected.sentAt)}
            </time>
          </div>
        </header>
        <article className="min-h-0 flex-1 overflow-y-auto px-4 py-5">
          <NotificationMarkdown body={selected.body} />
          {selected.link ? (
            <a
              className="mt-6 inline-flex items-center gap-2 rounded border px-3 py-2 text-sm font-medium hover:bg-panel-muted"
              href={selected.link}
            >
              Open link <Kbd>Enter ↵</Kbd>
            </a>
          ) : null}
        </article>
      </>
    ) : notification.id ? (
      <div className="grid min-h-0 flex-1 place-items-center p-6 text-center">
        <div>
          <p className="font-medium">Notification not found</p>
          <p className="mt-1 text-sm text-foreground/60">
            It may be outside the current channel or no longer available.
          </p>
          <button
            className="mt-4 rounded border px-3 py-2 text-sm hover:bg-panel-muted"
            onClick={onBack}
            type="button"
          >
            Back to messages
          </button>
        </div>
      </div>
    ) : (
      <div className="grid min-h-0 flex-1 place-items-center p-6 text-center text-sm text-foreground/60">
        Select a notification to read it.
      </div>
    )}
  </section>
);
