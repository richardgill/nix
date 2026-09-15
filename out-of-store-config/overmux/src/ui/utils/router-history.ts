import {
  createBrowserHistory,
  type HistoryLocation,
  type RegisteredRouter,
} from "@tanstack/react-router";

type ParsedHistoryState = HistoryLocation["state"];

// TanStack Router Core 1.171.27 serializes masked hashes without `#` but reload parsing strips one.
// Remove after https://github.com/TanStack/router/blob/v1.171.27/packages/router-core/src/router.ts
// keeps `commitLocation` and `parseLocation` consistent, then retain the browser-history regression test.
type MaskedHistoryState = ParsedHistoryState & {
  __tempLocation?: { hash?: unknown };
};

// TanStack does not expose its masked location metadata in the public history state type.
export const workspaceNavigationHash = (
  router: RegisteredRouter,
  { masked }: { masked: boolean },
): string => {
  const state = router.history.location.state as MaskedHistoryState;
  const workspaceHash = state.__tempLocation?.hash;
  const hash = (
    typeof workspaceHash === "string" ? workspaceHash : router.stores.location.get().hash
  ).replace(/^#/, "");
  // Masked locations are parsed as browser history and require their leading hash marker.
  return masked && hash ? `#${hash}` : hash;
};

const restoreMaskedHash = (state: ParsedHistoryState | null) => {
  if (!state) return {};
  const masked = state as MaskedHistoryState;
  const hash = masked.__tempLocation?.hash;
  if (typeof hash !== "string" || !hash || hash.startsWith("#")) {
    return state;
  }
  return {
    ...state,
    __tempLocation: { ...masked.__tempLocation, hash: `#${hash}` },
  };
};

const parseBrowserLocation = (): HistoryLocation => ({
  hash: window.location.hash,
  href: `${window.location.pathname}${window.location.search}${window.location.hash}`,
  pathname: window.location.pathname,
  search: window.location.search,
  state: restoreMaskedHash(window.history.state),
});

export const createOvermuxHistory = () =>
  createBrowserHistory({ parseLocation: parseBrowserLocation });
