import { act, createElement, useRef } from "react";
import { createRoot } from "react-dom/client";
import {
  createMemoryHistory,
  createRootRoute,
  createRoute,
  createRouter,
  Outlet,
  RouterProvider,
} from "@tanstack/react-router";
import { afterEach, expect, test as testCases } from "vitest";
import { z } from "zod";

import { notificationPath, notificationSearchSchema } from "../notifications/routing";
import { useRouteState } from "./use-route-state";

(globalThis as { IS_REACT_ACT_ENVIRONMENT: boolean }).IS_REACT_ACT_ENVIRONMENT =
  true;

let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;
let activeHistory: ReturnType<typeof createMemoryHistory> | undefined;

const RouteStateProbe = ({ masked }: { masked: boolean }) => {
  const [selection, setSelection] = useRouteState({
    getVisibleLocation: masked
      ? (next) =>
          next ? { to: notificationPath(next.channel, next.id) } : undefined
      : undefined,
    historyMode: "replace",
    routeId: "/tmux",
    searchParam: "notification",
  });
  const retainedSetSelection = useRef(setSelection);

  return (
    <>
      <output>{selection?.id ?? selection?.channel ?? "closed"}</output>
      <button
        onClick={() => void setSelection({ channel: "agent" })}
        type="button"
      >
        Select agent
      </button>
      <button
        onClick={() =>
          void retainedSetSelection.current((previous) =>
            previous ? { ...previous, id: "42" } : undefined,
          )
        }
        type="button"
      >
        Select retained detail
      </button>
      <button
        onClick={() =>
          void setSelection(
            (previous) =>
              previous ? { ...previous, id: "43" } : undefined,
            { historyMode: "push" },
          )
        }
        type="button"
      >
        Push detail
      </button>
      <button onClick={() => void setSelection(undefined)} type="button">
        Clear selection
      </button>
    </>
  );
};

const MaskedRouteStateProbe = () => <RouteStateProbe masked />;
const UnmaskedRouteStateProbe = () => <RouteStateProbe masked={false} />;
const defaultNotificationSearchSchema = z.object({
  notification: z
    .object({
      channel: z.enum(["all", "agent", "github"]),
      id: z.string().min(1).optional(),
    })
    .default({ channel: "all" }),
});

const setup = async (masked = true, useDefaultSelection = false) => {
  const rootRoute = createRootRoute({ component: Outlet });
  const notificationsRoute = createRoute({
    getParentRoute: () => rootRoute,
    path: "notifications",
  });
  const notificationChannelRoute = createRoute({
    getParentRoute: () => notificationsRoute,
    path: "$channel",
  });
  const notificationDetailRoute = createRoute({
    getParentRoute: () => notificationChannelRoute,
    path: "$id",
  });
  const tmuxRoute = createRoute({
    component: masked ? MaskedRouteStateProbe : UnmaskedRouteStateProbe,
    getParentRoute: () => rootRoute,
    path: "tmux",
    validateSearch: useDefaultSelection
      ? defaultNotificationSearchSchema
      : notificationSearchSchema,
  });
  const history = createMemoryHistory({
    initialEntries: ["/tmux?filter=active&pane=2#bottom"],
  });
  const router = createRouter({
    history,
    routeTree: rootRoute.addChildren([
      notificationsRoute.addChildren([
        notificationChannelRoute.addChildren([notificationDetailRoute]),
      ]),
      tmuxRoute,
    ]),
  });

  activeHistory = history;
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);
  await act(async () => {
    root.render(createElement(RouterProvider, { router }));
  });
  return router;
};

const click = async (label: string) => {
  const button = [...document.querySelectorAll<HTMLButtonElement>("button")].find(
    (candidate) => candidate.textContent === label,
  );
  await act(async () => button?.click());
};

afterEach(async () => {
  await act(async () => root?.unmount());
  activeHistory?.destroy();
  container?.remove();
});

testCases("updates route state directly and functionally while preserving workspace state", async () => {
  const router = await setup();

  await click("Select agent");
  expect(router.history.length).toBe(1);
  expect(router.history.location.pathname).toBe("/notifications/agent");
  expect(router.stores.location.get()).toMatchObject({
    hash: "bottom",
    pathname: "/tmux",
    search: { filter: "active", notification: { channel: "agent" }, pane: 2 },
  });

  await click("Select retained detail");
  expect(router.history.location.pathname).toBe("/notifications/agent/42");
  expect(router.stores.location.get().search).toMatchObject({
    filter: "active",
    notification: { channel: "agent", id: "42" },
    pane: 2,
  });

  await click("Clear selection");
  expect(router.history.location.pathname).toBe("/tmux");
  expect(router.history.location.hash).toBe("#bottom");
  expect(router.stores.location.get().search).toMatchObject({
    filter: "active",
    pane: 2,
  });
  expect(router.stores.location.get().search.notification).toBeUndefined();
});

testCases("functional updates receive validated defaults from the active route match", async () => {
  const router = await setup(true, true);

  await click("Select retained detail");

  expect(router.history.location.pathname).toBe("/notifications/all/42");
  expect(router.stores.location.get().search.notification).toEqual({
    channel: "all",
    id: "42",
  });
});

testCases("updates ordinary route state without a visible mask", async () => {
  const router = await setup(false);

  await click("Select agent");
  await click("Select retained detail");

  expect(router.history.location.pathname).toBe("/tmux");
  expect(router.history.location.hash).toBe("#bottom");
  expect(router.stores.location.get().search).toMatchObject({
    filter: "active",
    notification: { channel: "agent", id: "42" },
    pane: 2,
  });
});

testCases("uses the configured replace mode and allows a push override through masked history", async () => {
  const router = await setup();

  await click("Select agent");
  await click("Push detail");
  expect(router.history.length).toBe(2);
  expect(router.history.location.pathname).toBe("/notifications/agent/43");

  await act(async () => router.history.back());
  expect(router.history.location.pathname).toBe("/notifications/agent");
  expect(router.stores.location.get().search.notification).toEqual({
    channel: "agent",
  });

  await act(async () => router.history.forward());
  expect(router.history.location.pathname).toBe("/notifications/agent/43");
  expect(router.stores.location.get().search.notification).toEqual({
    channel: "agent",
    id: "43",
  });
});
