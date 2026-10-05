import { defineCommandRegistry } from "overmux/client";

import type { ServerConfig } from "./utils/overmux-hooks";

export const commands = defineCommandRegistry<ServerConfig>()({
  openGitWorkingTree: {
    defaultBindings: [
      ["§", "D", "B"],
      ["F12", "D", "B"],
    ],
    title: "Show working tree against origin/main",
  },
  openPullRequest: {
    defaultBindings: [
      ["§", "P", "R"],
      ["F12", "P", "R"],
    ],
    title: "Open pull request for current folder",
  },
  openGitChanges: {
    defaultBindings: [
      ["§", "D", "D"],
      ["F12", "D", "D"],
    ],
    title: "Show staged and unstaged git changes",
  },
  openNotifications: {
    defaultBindings: [
      ["§", "N", "N"],
      ["F12", "N", "N"],
    ],
    title: "Open notifications",
  },
  openGithubNotifications: {
    defaultBindings: [
      ["§", "N", "G"],
      ["F12", "N", "G"],
    ],
    title: "Open GitHub notifications",
  },
  openAgentNotifications: {
    defaultBindings: [
      ["§", "N", "A"],
      ["F12", "N", "A"],
    ],
    title: "Open Agent notifications",
  },
});
