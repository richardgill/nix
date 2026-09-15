import { useRouter, useSearch } from "@tanstack/react-router";
import type {
  RegisteredRouter,
  RouteById,
  RouteIds,
} from "@tanstack/react-router";

import { workspaceNavigationHash } from "./router-history";

type RegisteredRouteId = RouteIds<RegisteredRouter["routeTree"]>;
type RouteSearch<TRouteId extends RegisteredRouteId> = RouteById<
  RegisteredRouter["routeTree"],
  TRouteId
>["types"]["fullSearchSchema"];
type RouteSearchParam<TRouteId extends RegisteredRouteId> = Extract<
  keyof RouteSearch<TRouteId>,
  string
>;
type RouteSelection<
  TRouteId extends RegisteredRouteId,
  TSearchParam extends RouteSearchParam<TRouteId>,
> = RouteSearch<TRouteId>[TSearchParam];
type HistoryMode = "push" | "replace";
type VisibleLocation = { to: string };

type RouteStateOptions<
  TRouteId extends RegisteredRouteId,
  TSearchParam extends RouteSearchParam<TRouteId>,
> = {
  routeId: TRouteId;
  searchParam: TSearchParam;
  historyMode: HistoryMode;
  getVisibleLocation?: (
    selection: RouteSelection<TRouteId, TSearchParam>,
  ) => VisibleLocation | undefined;
};

type RouteStateUpdate<TSelection> =
  | TSelection
  | ((selection: TSelection) => TSelection);

type RouteStateSetter<TSelection> = (
  selection: RouteStateUpdate<TSelection>,
  options?: { historyMode?: HistoryMode },
) => Promise<void>;

// Typed URL state from an active route's search schema; preserves other search fields and hash.
// Back/Forward updates the value. Optional getVisibleLocation masks the displayed URL.
// const [value, setValue] = useRouteState({
//   routeId: "/tmux", searchParam: "notification", historyMode: "replace",
// });
// await setValue({ channel: "all" }, { historyMode: "push" });
// await setValue(previous => previous && { ...previous, id: "42" });
// await setValue(undefined); // Remove the search field.
export const useRouteState = <
  TRouteId extends RegisteredRouteId,
  TSearchParam extends RouteSearchParam<TRouteId>,
>({
  routeId,
  searchParam,
  historyMode,
  getVisibleLocation,
}: RouteStateOptions<TRouteId, TSearchParam>): [
  RouteSelection<TRouteId, TSearchParam>,
  RouteStateSetter<RouteSelection<TRouteId, TSearchParam>>,
] => {
  const router = useRouter();
  // TanStack's useSearch result does not preserve the relationship between a route and key.
  const routeSearch = useSearch({ from: routeId });
  const selection = routeSearch[searchParam] as RouteSelection<
    TRouteId,
    TSearchParam
  >;

  const setSelection: RouteStateSetter<typeof selection> = (
    update,
    options,
  ) => {
    // Read the latest validated match so retained setters receive schema defaults.
    const routeMatch = router.state.matches.find(
      (match) => match.routeId === routeId,
    );
    if (!routeMatch) {
      throw new Error(`Route state requires an active ${routeId} match`);
    }
    const currentSelection = routeMatch.search[
      searchParam as keyof typeof routeMatch.search
    ] as RouteSelection<TRouteId, TSearchParam>;
    // `typeof` cannot narrow generic selections because they could themselves be callable.
    const next =
      typeof update === "function"
        ? (update as (
            selection: RouteSelection<TRouteId, TSearchParam>,
          ) => RouteSelection<TRouteId, TSearchParam>)(currentSelection)
        : update;

    const visibleLocation = getVisibleLocation?.(next);
    return router.navigate({
      hash: workspaceNavigationHash(router, { masked: Boolean(visibleLocation) }),
      mask: visibleLocation,
      replace: (options?.historyMode ?? historyMode) === "replace",
      search: (current) => {
        if (next === undefined) {
          const { [searchParam]: _, ...remaining } = current;
          return remaining;
        }
        return { ...current, [searchParam]: next };
      },
      to: ".",
    });
  };

  return [selection, setSelection];
};
