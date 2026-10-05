type NotificationTime = {
  label: string;
  time?: string;
};

const sameDay = (left: Date, right: Date) =>
  left.getFullYear() === right.getFullYear() &&
  left.getMonth() === right.getMonth() &&
  left.getDate() === right.getDate();

export const notificationTime = (
  timestamp: string,
  now: number,
): NotificationTime => {
  const sentAt = new Date(timestamp);
  const current = new Date(now);
  const elapsed = Math.max(0, now - sentAt.getTime());
  const minutes = Math.floor(elapsed / 60_000);
  if (minutes < 1) return { label: "now" };
  if (minutes < 60) return { label: `${minutes}m` };
  if (sameDay(sentAt, current) && minutes < 6 * 60)
    return { label: `${Math.floor(minutes / 60)}h` };

  const time = `${String(sentAt.getHours()).padStart(2, "0")}:${String(sentAt.getMinutes()).padStart(2, "0")}`;
  if (sameDay(sentAt, current)) return { label: time };

  const yesterday = new Date(now);
  yesterday.setDate(current.getDate() - 1);
  if (sameDay(sentAt, yesterday)) return { label: "Yesterday", time };
  if (elapsed < 7 * 24 * 60 * 60_000) {
    const label = new Intl.DateTimeFormat("en-GB", { weekday: "short" }).format(
      sentAt,
    );
    return { label, time };
  }

  const month = new Intl.DateTimeFormat("en-US", { month: "short" }).format(
    sentAt,
  );
  const year =
    sentAt.getFullYear() !== current.getFullYear()
      ? ` ${sentAt.getFullYear()}`
      : "";
  return { label: `${sentAt.getDate()} ${month}${year}`, time };
};
