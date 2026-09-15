import {
  createRootRoute,
  createRoute,
  createRouter,
  Outlet,
  useRouter,
} from "@tanstack/react-router";
import { useCommand } from "overmux/client";

import { commands } from "./commands";
import {
  NotificationsRedirectRoute,
  notificationSearchSchema,
  openNotifications,
} from "./notifications";
import { createOvermuxHistory } from "./utils/router-history";
import { RootTmuxRedirectRoute } from "./components/routes/root-tmux-redirect-route";
import { TmuxTerminalLayoutRoute } from "./components/routes/tmux-terminal-layout-route";

const RootRoute = () => {
  const router = useRouter();
  useCommand(commands.openNotifications, {
    run: () => openNotifications(router),
  });
  return <Outlet />;
};

const rootRoute = createRootRoute({ component: RootRoute });
const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/",
  component: RootTmuxRedirectRoute,
});
const notificationsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "notifications",
  component: Outlet,
});
const notificationsIndexRoute = createRoute({
  getParentRoute: () => notificationsRoute,
  path: "/",
  component: NotificationsRedirectRoute,
});
const notificationChannelRoute = createRoute({
  getParentRoute: () => notificationsRoute,
  path: "$channel",
  component: NotificationsRedirectRoute,
});
const notificationDetailRoute = createRoute({
  getParentRoute: () => notificationChannelRoute,
  path: "$id",
});
const tmuxRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "tmux",
  validateSearch: notificationSearchSchema,
  component: TmuxTerminalLayoutRoute,
});
const tmuxIndexRoute = createRoute({
  getParentRoute: () => tmuxRoute,
  path: "/",
  component: RootTmuxRedirectRoute,
});
const sessionRoute = createRoute({
  getParentRoute: () => tmuxRoute,
  path: "$sessionId",
});
const windowRoute = createRoute({
  getParentRoute: () => tmuxRoute,
  path: "$sessionId/$windowId",
});
const paneRoute = createRoute({
  getParentRoute: () => tmuxRoute,
  path: "$sessionId/$windowId/$paneId",
});
const routeTree = rootRoute.addChildren([
  indexRoute,
  notificationsRoute.addChildren([
    notificationsIndexRoute,
    notificationChannelRoute.addChildren([notificationDetailRoute]),
  ]),
  tmuxRoute.addChildren([tmuxIndexRoute, sessionRoute, windowRoute, paneRoute]),
]);
export const routes = createRouter({
  // Work around TanStack's masked-hash reload bug so refresh preserves the notification URL and workspace hash.
  history: createOvermuxHistory(),
  routeTree,
});

declare module "@tanstack/react-router" {
  interface Register {
    router: typeof routes;
  }
}
