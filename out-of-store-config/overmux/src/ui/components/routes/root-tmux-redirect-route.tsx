import { useNavigate, useSearch } from "@tanstack/react-router";
import { useEffect } from "react";

import { useResource } from "../../utils/overmux-hooks";
import {
  notificationFromSearch,
  notificationPath,
} from "../../notifications";
import { tmuxParamsFromTarget } from "../../utils/tmux-routing";

export const RootTmuxRedirectRoute = () => {
  const tmux = useResource({ id: "tmuxState" });
  const navigate = useNavigate();
  const search = useSearch({ strict: false });
  const notification = notificationFromSearch(search);
  const session = tmux.data?.hierarchy.sessions.find(({ windows }) =>
    windows.some(({ panes }) => panes.length > 0),
  );

  useEffect(() => {
    if (tmux.status === "success" && session) {
      const params = tmuxParamsFromTarget({ sessionId: session.id });
      void navigate({
        hash: true,
        ...(notification
          ? { mask: { to: notificationPath(notification.channel, notification.id) } }
          : {}),
        to: "/tmux/$sessionId",
        params,
        search: true,
        replace: true,
      });
    }
  }, [navigate, notification, session, tmux.status]);

  const message =
    tmux.status === "error"
      ? tmux.error.message
      : tmux.status === "success"
        ? session
          ? "Opening tmux session…"
          : "No tmux sessions."
        : "Loading tmux…";

  return <main className="p-4">{message}</main>;
};

