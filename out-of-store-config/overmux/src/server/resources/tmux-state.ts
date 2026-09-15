import type { TmuxState, TmuxStateResource } from "@overmux/tmux/server";
import type { TmuxSessionRecency } from "./tmux-session-recency";

// recency, then code, then background
export const orderTmuxState = ({
  raw,
  recency,
}: {
  raw: TmuxState;
  recency: TmuxSessionRecency;
}): TmuxState => {
  const recordedAtByName = new Map(Object.entries(recency.recordedAtByName));
  const sessions = [...raw.hierarchy.sessions].sort((left, right) => {
    const leftPinned =
      left.name === "code" ? 1 : left.name === "background" ? 2 : 0;
    const rightPinned =
      right.name === "code" ? 1 : right.name === "background" ? 2 : 0;
    return (
      leftPinned - rightPinned ||
      (recordedAtByName.get(right.name) ?? 0) -
        (recordedAtByName.get(left.name) ?? 0) ||
      (recency.liveById[right.id]?.lastAttached ?? 0) -
        (recency.liveById[left.id]?.lastAttached ?? 0) ||
      (recency.liveById[right.id]?.activity ?? 0) -
        (recency.liveById[left.id]?.activity ?? 0) ||
      left.name.localeCompare(right.name)
    );
  });
  return { ...raw, hierarchy: { ...raw.hierarchy, sessions } };
};

export const orderedTmuxStateResource = ({
  contract,
}: Pick<TmuxStateResource, "contract">) => ({
  contract,
  kind: "derived" as const,
  dependencies: { raw: "tmuxStateRaw", recency: "tmuxSessionRecency" } as const,
  combine: orderTmuxState,
});
