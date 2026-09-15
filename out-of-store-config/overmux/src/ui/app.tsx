import "./css/styles.css";
import "./css/markdown.css";

import { RouterProvider } from "@tanstack/react-router";
import { defineOvermuxClient } from "overmux/client";

import { commands } from "./commands";
import { routes } from "./routes";

const DesktopTerminalApp = () => <RouterProvider router={routes} />;

export default defineOvermuxClient({
  chordPrefixes: [
    { binding: "F12", unmatched: "replay-to-focused-input" },
    { binding: "§", unmatched: "replay-to-focused-input" },
  ],
  commands,
  component: DesktopTerminalApp,
});
