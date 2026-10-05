import { gitChangesResource, gitDiffResource } from "@overmux/git/server";
import { defineOvermuxServer } from "overmux";
import { getOvermuxPaths } from "overmux/server";
import {
  createPiSessionStatusSource,
  definePiAgents,
  piConversationStream,
} from "@overmux/pi/server";
import {
  defineTmuxControlBackend,
  tmuxOperations,
  tmuxResource,
  tmuxStream,
} from "@overmux/tmux/server";
import { join } from "node:path";

import { gitRepositoryResource } from "./git-repository";
import { notificationOperation, notificationsResource } from "./notifications";
import { findPullRequestOperation } from "./pull-request";
import { tmuxSessionRecencyResource } from "./resources/tmux-session-recency";
import { orderedTmuxStateResource } from "./resources/tmux-state";
import { customTmuxOperations } from "./tmux-operations";

const tmuxBackend = defineTmuxControlBackend({});
const tmuxRaw = tmuxResource({ backend: tmuxBackend });
const tmuxSessionRecency = tmuxSessionRecencyResource({ backend: tmuxBackend });
const tmuxTerminal = tmuxStream({ backend: tmuxBackend });

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
    findPullRequest: findPullRequestOperation,
    notification: notificationOperation,
    ...tmuxOperations({ backend: tmuxBackend }),
    ...customTmuxOperations({ backend: tmuxBackend }),
  },
  resources: {
    gitChanges: gitChangesResource({ allowedRoots: ["/home/rich"] }),
    gitDiff: gitDiffResource({ allowedRoots: ["/home/rich"] }),
    gitRepository: gitRepositoryResource,
    notifications: notificationsResource,
    tmuxRaw,
    tmuxSessionRecency,
    tmux: orderedTmuxStateResource({ contract: tmuxRaw.contract }),
  },
  streams: {
    piConversation: piConversationStream({ agents: piAgents }),
    tmux: tmuxTerminal,
  },
});
