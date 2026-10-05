import { defineOvermuxDesktopConfig } from "@overmux/desktop";

export default defineOvermuxDesktopConfig({
  menuBar: "hidden",
  titleBar: "hidden",
  onBeforeInputEvent: ({ event, input, webContents }) => {
    if (process.platform !== "linux" || input.type !== "keyDown") return;

    const superOnly =
      input.meta && !input.control && !input.alt && !input.shift;
    if (!superOnly) return;

    const key = input.key.toLowerCase();
    if (key !== "c" && key !== "v") return;

    event.preventDefault();
    if (key === "c") webContents.copy();
    else webContents.paste();
  },
});
