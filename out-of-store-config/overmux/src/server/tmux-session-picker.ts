import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import {
  mkdir,
  readFile,
  realpath,
  rename,
  stat,
  writeFile,
} from "node:fs/promises";
import { basename, dirname, join } from "node:path";
import { promisify } from "node:util";
import type {
  TmuxSessionPicker,
  TmuxSessionPickerEntry,
} from "../zod-schemas";

const execFileAsync = promisify(execFile);
const fieldSeparator = "\u001f";
const sessionFormat = [
  "#{session_name}",
  "#{session_id}",
  "#{session_created}",
  "#{?session_last_attached,#{session_last_attached},0}",
  "#{session_activity}",
  "#{session_path}",
].join(fieldSeparator);
const sessionVisibilityFormat = [
  "#{session_name}",
  "#{session_id}",
  "#{session_created}",
  "#{session_path}",
].join(fieldSeparator);

type TmuxCommandResult = { stderr: string; stdout: string };
type PickerAction = TmuxSessionPickerEntry["actions"][number];
type SessionReference = {
  created: string;
  id: string;
  name: string;
  path: string;
};
type SessionIdentity = SessionReference & {
  activity: number;
  lastAttached: number;
};
type QuarantineRow = SessionReference & {
  quarantineAt: number;
};
type InternalEntry = {
  actions: PickerAction[];
  identity?: SessionIdentity;
  kind: "active" | "directory" | "inactive" | "quarantined";
  label: string;
  path: string;
  timestamp: number;
};

export type TmuxSessionPickerExternalCommand = (
  command: string,
  args: readonly string[],
  options: { signal?: AbortSignal },
) => Promise<TmuxCommandResult>;

export type TmuxSessionPickerOptions = {
  execute?: TmuxSessionPickerExternalCommand;
  home?: string;
  pathExists?: (path: string) => Promise<boolean>;
  quarantineCommand?: string;
  quarantineFile: string;
  recencyFile: string;
  sessionNameForPath?: (path: string) => Promise<string> | string;
  zoxideCommand?: string;
};

type PickerDependencies = {
  killSession: (
    sessionId: string,
    signal?: AbortSignal,
  ) => Promise<{ forced: boolean }>;
  refreshTmux: () => Promise<void>;
  runTmux: (
    args: readonly string[],
    signal?: AbortSignal,
  ) => Promise<TmuxCommandResult>;
};

const defaultExternalCommand: TmuxSessionPickerExternalCommand = async (
  command,
  args,
  { signal },
) => {
  const { stderr, stdout } = await execFileAsync(command, [...args], {
    signal,
  });
  return { stderr, stdout };
};

const lines = (value: string) => value.split("\n").filter(Boolean);
const rows = (value: string) => lines(value).map((line) => line.split("\t"));
const number = (value: string) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};
const identityKey = ({ created, id, name }: SessionReference) =>
  `${id}\u0000${created}\u0000${name}`;
const safeDisplay = (value: string) =>
  [...value]
    .map((character) => {
      const code = character.codePointAt(0) ?? 0;
      return code <= 31 || code === 127 ? " " : character;
    })
    .join("")
    .trim()
    .slice(0, 512) || "session";
const displayPath = (path: string, home?: string) =>
  safeDisplay(
    path === home
      ? "~"
      : home && path.startsWith(`${home}/`)
        ? `~${path.slice(home.length)}`
        : path,
  );
const optionalFile = async (path: string) => {
  try {
    return await readFile(path, "utf8");
  } catch (cause) {
    if ((cause as NodeJS.ErrnoException).code === "ENOENT") {
      return "";
    }
    throw cause;
  }
};
const defaultPathExists = (path: string) =>
  stat(path)
    .then((value) => value.isDirectory())
    .catch(() => false);

const sessionReference = ({
  created,
  id,
  name,
  path,
}: SessionReference): SessionReference | undefined =>
  name && /^\$\d+$/.test(id) && created && path
    ? { created, id, name, path }
    : undefined;

const parseSessions = (output: string) =>
  lines(output).flatMap((line): SessionIdentity[] => {
    const [
      name = "",
      id = "",
      created = "",
      lastAttached = "",
      activity = "",
      path = "",
    ] = line.split(fieldSeparator);
    const reference = sessionReference({ created, id, name, path });
    return reference
      ? [
          {
            ...reference,
            activity: number(activity),
            lastAttached: number(lastAttached),
          },
        ]
      : [];
  });

const parseVisibilitySessions = (output: string) =>
  lines(output).flatMap((line): SessionReference[] => {
    const [name = "", id = "", created = "", path = ""] =
      line.split(fieldSeparator);
    const reference = sessionReference({ created, id, name, path });
    return reference ? [reference] : [];
  });

const parseQuarantine = (content: string) =>
  rows(content).flatMap((fields): QuarantineRow[] => {
    if (fields.length !== 8) {
      return [];
    }
    const [quarantineAt = "", , id = "", created = "", name = "", path = ""] =
      fields;
    return quarantineAt && id && created && name && path
      ? [{ created, id, name, path, quarantineAt: number(quarantineAt) }]
      : [];
  });

const recencyRows = (content: string) =>
  rows(content).flatMap((fields) => {
    const [recordedAt = "", name = "", path = ""] = fields;
    return fields.length >= 3 && recordedAt && name && path
      ? [{ name, path, timestamp: number(recordedAt) }]
      : [];
  });

const pinnedEntries = (sessions: SessionIdentity[]) =>
  ["code", "background"].flatMap((name): InternalEntry[] => {
    const identity = sessions.find((session) => session.name === name);
    return identity
      ? [
          {
            actions: ["connect", "kill"],
            identity,
            kind: "active",
            label: identity.name,
            path: identity.path,
            timestamp: 0,
          },
        ]
      : [];
  });

const ordinaryActiveEntries = ({
  quarantine,
  recency,
  sessions,
}: {
  quarantine: Map<string, QuarantineRow>;
  recency: ReturnType<typeof recencyRows>;
  sessions: SessionIdentity[];
}) => {
  const recentByName = new Map<string, number>();
  recency.forEach(({ name, timestamp }) => {
    if (!recentByName.has(name)) {
      recentByName.set(name, timestamp);
    }
  });
  return sessions
    .filter(
      (session) =>
        !["code", "background"].includes(session.name) &&
        !quarantine.has(identityKey(session)),
    )
    .map(
      (identity): InternalEntry => ({
        actions: ["connect", "kill", "quarantine"],
        identity,
        kind: "active",
        label: identity.name,
        path: identity.path,
        timestamp: recentByName.get(identity.name) ?? 0,
      }),
    )
    .sort(
      (left, right) =>
        right.timestamp - left.timestamp ||
        (right.identity?.lastAttached ?? 0) -
          (left.identity?.lastAttached ?? 0) ||
        (right.identity?.activity ?? 0) - (left.identity?.activity ?? 0) ||
        left.label.localeCompare(right.label),
    );
};

const inactiveEntries = async ({
  exists,
  quarantine,
  recency,
  sessions,
}: {
  exists: (path: string) => Promise<boolean>;
  quarantine: QuarantineRow[];
  recency: ReturnType<typeof recencyRows>;
  sessions: SessionIdentity[];
}) => {
  const sessionsByIdentity = new Map(
    sessions.map((session) => [identityKey(session), session]),
  );
  const existingNames = new Set(sessions.map(({ name }) => name));
  const candidates: InternalEntry[] = [
    ...quarantine.flatMap((row): InternalEntry[] => {
      const identity = sessionsByIdentity.get(identityKey(row));
      return identity
        ? [
            {
              actions: ["clear", "kill", "revive"],
              identity,
              kind: "quarantined",
              label: row.name,
              path: row.path,
              timestamp: row.quarantineAt,
            },
          ]
        : [];
    }),
    ...recency.flatMap(({ name, path, timestamp }): InternalEntry[] =>
      existingNames.has(name)
        ? []
        : [
            {
              actions: ["revive"],
              kind: "inactive",
              label: name,
              path,
              timestamp,
            },
          ],
    ),
  ];
  const available = await Promise.all(
    candidates.map(async (entry) => ({
      entry,
      exists: await exists(entry.path),
    })),
  );
  return available
    .filter(({ exists: present }) => present)
    .map(({ entry }) => entry)
    .sort(
      (left, right) =>
        right.timestamp - left.timestamp ||
        left.label.localeCompare(right.label),
    );
};

const directoryEntries = async ({
  exists,
  output,
}: {
  exists: (path: string) => Promise<boolean>;
  output: string;
}) => {
  const available = await Promise.all(
    lines(output).map(async (path) => ({ exists: await exists(path), path })),
  );
  return available.flatMap(({ exists: present, path }): InternalEntry[] =>
    present
      ? [
          {
            actions: ["create"],
            kind: "directory",
            label: path,
            path,
            timestamp: 0,
          },
        ]
      : [],
  );
};

const atomicWrite = async (path: string, content: string) => {
  await mkdir(dirname(path), { recursive: true });
  const temporary = join(
    dirname(path),
    `.${basename(path)}.${randomUUID()}.tmp`,
  );
  await writeFile(temporary, content);
  await rename(temporary, path);
};

const clearQuarantine = async (path: string, identity: SessionIdentity) => {
  const content = await optionalFile(path);
  const remaining = rows(content).filter((fields) => {
    if (fields.length !== 8) {
      return false;
    }
    const [, , id = "", created = "", name = ""] = fields;
    return (
      identityKey({ ...identity, created, id, name }) !== identityKey(identity)
    );
  });
  await atomicWrite(
    path,
    remaining.length
      ? `${remaining.map((fields) => fields.join("\t")).join("\n")}\n`
      : "",
  );
};

const updateRecency = async ({
  name,
  path,
  recencyFile,
}: {
  name: string;
  path: string;
  recencyFile: string;
}) => {
  const content = await optionalFile(recencyFile);
  const remaining = rows(content).filter(
    (fields) => fields.length >= 2 && fields[1] !== name,
  );
  const next = [
    `${Math.floor(Date.now() / 1_000)}\t${name}\t${path}`,
    ...remaining.map((fields) => fields.join("\t")),
  ];
  await atomicWrite(recencyFile, `${next.join("\n")}\n`);
};

const defaultSessionName = async (path: string) => {
  const resolved = await realpath(path);
  const siblingMain = await realpath(join(resolved, "..", "main")).catch(
    () => "",
  );
  const hasSiblingMain = siblingMain
    ? await stat(siblingMain)
        .then((value) => value.isDirectory())
        .catch(() => false)
    : false;
  return hasSiblingMain
    ? `${basename(dirname(resolved))}/${basename(resolved)}`
    : basename(resolved);
};

export const createTmuxSessionVisibility = (
  options: Pick<TmuxSessionPickerOptions, "quarantineFile">,
  dependencies: Pick<PickerDependencies, "runTmux">,
) => {
  let activeRefresh: Promise<boolean> | undefined;
  let current = { sessionIds: [] as string[] };
  let fingerprint = "";
  let initialized = false;

  const calculateRefresh = async (signal?: AbortSignal) => {
    signal?.throwIfAborted();
    const [sessionOutput, quarantineContent] = await Promise.all([
      dependencies
        .runTmux(["list-sessions", "-F", sessionVisibilityFormat], signal)
        .then(({ stdout }) => stdout)
        .catch(() => ""),
      optionalFile(options.quarantineFile),
    ]);
    const quarantine = new Set(
      parseQuarantine(quarantineContent).map(identityKey),
    );
    const sessionIds = parseVisibilitySessions(sessionOutput).flatMap(
      (session) =>
        ["code", "background"].includes(session.name) ||
        !quarantine.has(identityKey(session))
          ? [session.id]
          : [],
    );
    signal?.throwIfAborted();
    const nextFingerprint = JSON.stringify(sessionIds);
    if (nextFingerprint === fingerprint) {
      return false;
    }
    current = { sessionIds };
    fingerprint = nextFingerprint;
    return true;
  };

  const refresh = (signal?: AbortSignal) => {
    if (activeRefresh) {
      return activeRefresh;
    }
    const pending = calculateRefresh(signal).then((changed) => {
      initialized = true;
      return changed;
    });
    activeRefresh = pending;
    void pending.then(
      () => {
        if (activeRefresh === pending) {
          activeRefresh = undefined;
        }
      },
      () => {
        if (activeRefresh === pending) {
          activeRefresh = undefined;
        }
      },
    );
    return pending;
  };

  const initialize = async (signal?: AbortSignal) => {
    if (!initialized) {
      await refresh(signal);
    }
  };

  const snapshot = () => current;

  return { initialize, refresh, snapshot };
};

export const createTmuxSessionPicker = (
  options: TmuxSessionPickerOptions,
  dependencies: PickerDependencies,
) => {
  const execute = options.execute ?? defaultExternalCommand;
  const exists = options.pathExists ?? defaultPathExists;
  let currentSessions: SessionIdentity[] = [];
  let revision = 0;
  let fingerprint = "";
  let refreshQueue = Promise.resolve();
  let resolvedEntries = new Map<string, InternalEntry>();
  let zoxideOutput = "";
  let zoxideRequest: Promise<void> | undefined;

  const calculateRefresh = async (signal?: AbortSignal) => {
    signal?.throwIfAborted();
    if (!zoxideRequest) {
      zoxideRequest = execute(
        options.zoxideCommand ?? "zoxide",
        ["query", "-l"],
        {
          signal,
        },
      )
        .then(({ stdout }) => {
          zoxideOutput = stdout;
        })
        .catch(() => undefined)
        .finally(() => {
          zoxideRequest = undefined;
        });
    }
    const [sessionOutput, quarantineContent, recencyContent] =
      await Promise.all([
        dependencies
          .runTmux(["list-sessions", "-F", sessionFormat], signal)
          .then(({ stdout }) => stdout)
          .catch(() => ""),
        optionalFile(options.quarantineFile),
        optionalFile(options.recencyFile),
      ]);
    currentSessions = parseSessions(sessionOutput);
    const quarantineRows = parseQuarantine(quarantineContent);
    const quarantine = new Map(
      quarantineRows.map((row) => [identityKey(row), row]),
    );
    const recency = recencyRows(recencyContent);
    const entries = [
      ...ordinaryActiveEntries({
        quarantine,
        recency,
        sessions: currentSessions,
      }),
      ...(await inactiveEntries({
        exists,
        quarantine: quarantineRows,
        recency,
        sessions: currentSessions,
      })),
      ...(await directoryEntries({ exists, output: zoxideOutput })),
      ...pinnedEntries(currentSessions),
    ];
    signal?.throwIfAborted();
    const nextFingerprint = JSON.stringify(entries);
    if (nextFingerprint === fingerprint) {
      return false;
    }
    fingerprint = nextFingerprint;
    revision += 1;
    resolvedEntries = new Map(entries.map((entry) => [randomUUID(), entry]));
    return true;
  };

  const refresh = (signal?: AbortSignal) => {
    const pending = refreshQueue
      .catch(() => undefined)
      .then(() => calculateRefresh(signal));
    refreshQueue = pending.then(
      () => undefined,
      () => undefined,
    );
    return pending;
  };

  const snapshot = (): TmuxSessionPicker => ({
    entries: [...resolvedEntries].map(([ref, entry]) => ({
      actions: entry.actions,
      label:
        entry.kind === "directory"
          ? displayPath(entry.label, options.home)
          : safeDisplay(entry.label),
      pathDisplay: displayPath(entry.path, options.home),
      ref,
      ...(entry.identity ? { sessionId: entry.identity.id } : {}),
      state: entry.kind,
    })),
    revision,
  });

  const action = async (
    operation: PickerAction,
    expectedRevision: number,
    ref: string,
    signal?: AbortSignal,
  ): Promise<{ outcome: "stale" | "success"; sessionId?: string }> => {
    const entry = resolvedEntries.get(ref);
    if (
      expectedRevision !== revision ||
      !entry ||
      !entry.actions.includes(operation)
    ) {
      return { outcome: "stale" };
    }
    await dependencies.refreshTmux();
    const refreshedSessions = parseSessions(
      (
        await dependencies.runTmux(
          ["list-sessions", "-F", sessionFormat],
          signal,
        )
      ).stdout,
    );
    const identity = entry.identity;
    if (
      identity &&
      !refreshedSessions.some(
        (session) =>
          identityKey(session) === identityKey(identity) &&
          session.path === identity.path,
      )
    ) {
      return { outcome: "stale" };
    }
    if (
      ["create", "revive"].includes(operation) &&
      !(await exists(entry.path))
    ) {
      return { outcome: "stale" };
    }
    currentSessions = refreshedSessions;

    let selected: SessionIdentity | undefined;
    if (operation === "connect" && entry.identity) {
      selected = entry.identity;
    }
    if (operation === "clear" && entry.identity) {
      await clearQuarantine(options.quarantineFile, entry.identity);
    }
    if (operation === "revive" && entry.identity) {
      await clearQuarantine(options.quarantineFile, entry.identity);
      selected = entry.identity;
    }
    if (operation === "revive" && !entry.identity) {
      const created = await dependencies.runTmux(
        [
          "new-session",
          "-d",
          "-P",
          "-F",
          "#{session_id}",
          "-s",
          entry.label,
          "-c",
          entry.path,
        ],
        signal,
      );
      const sessionId = created.stdout.trim();
      if (!/^\$\d+$/.test(sessionId)) {
        throw new Error("Tmux did not return the revived session reference");
      }
      selected = {
        activity: 0,
        created: "pending",
        id: sessionId,
        lastAttached: 0,
        name: entry.label,
        path: entry.path,
      };
    }
    if (operation === "create") {
      await execute(options.zoxideCommand ?? "zoxide", ["add", entry.path], {
        signal,
      }).catch(() => undefined);
      const name = await (options.sessionNameForPath ?? defaultSessionName)(
        entry.path,
      );
      selected = currentSessions.find((session) => session.name === name);
      if (selected) {
        const selectedIdentity = selected;
        const quarantine = parseQuarantine(
          await optionalFile(options.quarantineFile),
        ).find((row) => identityKey(row) === identityKey(selectedIdentity));
        if (quarantine) {
          await clearQuarantine(options.quarantineFile, selectedIdentity);
        }
      } else {
        const created = await dependencies.runTmux(
          [
            "new-session",
            "-d",
            "-P",
            "-F",
            "#{session_id}",
            "-s",
            name,
            "-c",
            entry.path,
          ],
          signal,
        );
        const sessionId = created.stdout.trim();
        if (!/^\$\d+$/.test(sessionId)) {
          throw new Error("Tmux did not return the created session reference");
        }
        selected = {
          activity: 0,
          created: "pending",
          id: sessionId,
          lastAttached: 0,
          name,
          path: entry.path,
        };
      }
    }
    if (operation === "quarantine" && entry.identity) {
      if (!options.quarantineCommand) {
        throw new Error("Quarantine is not configured");
      }
      await execute(
        options.quarantineCommand,
        [
          "--manual-session",
          entry.identity.name,
          "--expected-id",
          entry.identity.id,
          "--expected-created",
          entry.identity.created,
        ],
        { signal },
      );
    }
    if (operation === "kill" && entry.identity) {
      await dependencies.killSession(entry.identity.id, signal);
    }
    if (selected) {
      await updateRecency({
        name: selected.name,
        path: selected.path,
        recencyFile: options.recencyFile,
      });
    }
    return { outcome: "success", sessionId: selected?.id };
  };

  return { action, refresh, snapshot };
};
