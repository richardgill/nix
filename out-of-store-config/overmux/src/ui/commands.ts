import { defineCommandRegistry } from "overmux/client";

import type { ServerConfig } from "./utils/overmux-hooks";

export const commands = defineCommandRegistry<ServerConfig>()({
  openNotifications: {
    defaultBindings: [
      ["§", "N", "N"],
      ["F12", "N", "N"],
    ],
    title: "Open notifications",
  },
});
