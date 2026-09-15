import { defineOvermuxServer } from "overmux";
import { getOvermuxPaths } from "overmux/server";
import {
  createPiSessionStatusSource,
  definePiAgents,
  piConversationStream,
} from "@overmux/pi/server";
import {
  defineTmuxControlBackend,
  tmuxStateResource,
  tmuxTerminalStream,
} from "@overmux/tmux/server";
import { join } from "node:path";

import { notificationOperation, notificationsResource } from "./notifications";
import { tmuxSessionRecencyResource } from "./resources/tmux-session-recency";
import { orderedTmuxStateResource } from "./resources/tmux-state";
import { tmuxOperationHandlers } from "./tmux-operations";

const tmuxBackend = defineTmuxControlBackend({});
const tmuxStateRaw = tmuxStateResource({ backend: tmuxBackend });
const tmuxSessionRecency = tmuxSessionRecencyResource({ backend: tmuxBackend });
const tmuxTerminal = tmuxTerminalStream({ backend: tmuxBackend });

const liveEventsDir = join(getOvermuxPaths().stateDir, "pi", "events");
const piSessions = createPiSessionStatusSource({ rootDir: liveEventsDir });
const piAgents = definePiAgents({
  liveEventsDir,
  sessions: {
    list: async () =>
      (await piSessions.list()).map(({ sessionFile, sessionId }) => ({
        id: sessionId,
        sessionFile,
      })),
    subscribe: piSessions.subscribe,
  },
});

export default defineOvermuxServer({
  operations: {
    notification: notificationOperation,
    ...tmuxOperationHandlers({ backend: tmuxBackend }),
  },
  resources: {
    notifications: notificationsResource,
    tmuxStateRaw,
    tmuxSessionRecency,
    tmuxState: orderedTmuxStateResource({ contract: tmuxStateRaw.contract }),
  },
  streams: {
    piConversation: piConversationStream({ agents: piAgents }),
    tmuxTerminal,
  },
});
