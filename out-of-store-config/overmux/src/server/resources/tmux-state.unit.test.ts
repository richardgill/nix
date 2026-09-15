import { tmuxStateResource, type TmuxState } from "@overmux/tmux/server";
import { expect, test as testCases, vi } from "vitest";
import { orderTmuxState, orderedTmuxStateResource } from "./tmux-state";

const tmuxState = (names: string[]): TmuxState => ({
  backend: { id: "default" },
  connected: true,
  hierarchy: {
    sessions: names.map((name, index) => ({
      id: `$${index}`,
      name,
      activeWindowId: `@${index}`,
      windows: [],
    })),
  },
});

// Each row makes a higher-priority key disagree with the lower-priority keys.
testCases.each([
  {
    label: "recency before attachment",
    recency: [3, 2],
    attached: [0, 99],
    activity: [0, 99],
    expected: ["z", "a"],
  },
  {
    label: "attachment before activity",
    recency: [0, 0],
    attached: [2, 1],
    activity: [0, 99],
    expected: ["z", "a"],
  },
  {
    label: "activity before name",
    recency: [0, 0],
    attached: [0, 0],
    activity: [2, 1],
    expected: ["z", "a"],
  },
  {
    label: "name",
    recency: [0, 0],
    attached: [0, 0],
    activity: [0, 0],
    expected: ["a", "z"],
  },
])("orders by $label", ({ recency, attached, activity, expected }) => {
  const result = orderTmuxState({
    raw: tmuxState(["z", "a"]),
    recency: {
      recordedAtByName: { z: recency[0]!, a: recency[1]! },
      liveById: {
        $0: { lastAttached: attached[0]!, activity: activity[0]! },
        $1: { lastAttached: attached[1]!, activity: activity[1]! },
      },
    },
  });
  expect(result.hierarchy.sessions.map(({ name }) => name)).toEqual(expected);
});

testCases(
  "pins code then background, retains every session and leaves raw state untouched",
  () => {
    const raw = tmuxState([
      "background",
      "code",
      "quarantined",
      "__overmux_shadow_live",
      "constructor",
      "newest",
    ]);
    const original = structuredClone(raw);
    Object.freeze(raw.hierarchy.sessions);
    const result = orderTmuxState({
      raw,
      recency: {
        recordedAtByName: { newest: 10, code: 100, background: 200 },
        liveById: {},
      },
    });
    expect(result.hierarchy.sessions.map(({ name }) => name)).toEqual([
      "newest",
      "__overmux_shadow_live",
      "constructor",
      "quarantined",
      "code",
      "background",
    ]);
    expect(raw).toEqual(original);
    expect(result.backend).toBe(raw.backend);
    expect(result.connected).toBe(raw.connected);
    result.hierarchy.sessions.forEach((session) =>
      expect(raw.hierarchy.sessions).toContain(session),
    );
    expect(result.hierarchy.sessions).toHaveLength(
      raw.hierarchy.sessions.length,
    );
  },
);

testCases("retains disconnected empty state", () => {
  const raw = { ...tmuxState([]), connected: false };
  expect(
    orderTmuxState({ raw, recency: { recordedAtByName: {}, liveById: {} } }),
  ).toEqual(raw);
});

testCases(
  "registers supported named dependencies, preserves the contract and combines new snapshots",
  () => {
    const raw = tmuxState(["z", "a"]);
    const backend = {
      id: "default",
      socket: "default",
      run: vi.fn(),
      refresh: vi.fn(),
      state: () => raw,
      subscribe: vi.fn(),
      subscribeNotifications: vi.fn(),
    };
    const source = tmuxStateResource({ backend });
    const derived = orderedTmuxStateResource({ contract: source.contract });
    expect(derived.kind).toBe("derived");
    expect(derived.contract).toBe(source.contract);
    expect(derived.dependencies).toEqual({
      raw: "tmuxStateRaw",
      recency: "tmuxSessionRecency",
    });
    const recency = { recordedAtByName: {}, liveById: {} };
    expect(derived.combine({ raw, recency }).hierarchy.sessions[0]?.name).toBe(
      "a",
    );
    expect(
      derived
        .combine({ raw: tmuxState(["new", "z", "a"]), recency })
        .hierarchy.sessions.map(({ name }) => name),
    ).toEqual(["a", "new", "z"]);
    expect(
      derived.combine({
        raw,
        recency: { ...recency, recordedAtByName: { z: 10 } },
      }).hierarchy.sessions[0]?.name,
    ).toBe("z");
  },
);
