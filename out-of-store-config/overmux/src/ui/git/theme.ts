import { registerCustomTheme } from "@pierre/diffs";
import tokyoNight from "@shikijs/themes/tokyo-night";
import type { GitDiffOptions } from "./pierre-diff";

// Preserve the app's Tokyo Night overrides from ../old/app.tsx.
const theme = "overmux-tokyo-night";
if (!import.meta.hot?.data?.themeRegistered)
  registerCustomTheme(theme, async () => ({
    ...tokyoNight,
    name: theme,
    tokenColors: [
      ...(tokyoNight.tokenColors ?? []),
      {
        scope: [
          "source.tsx entity.name.tag",
          "source.js.jsx entity.name.tag",
          "source.tsx entity.name.tag support.class.component",
          "source.js.jsx entity.name.tag support.class.component",
        ],
        settings: { foreground: "#2ac3de" },
      },
    ],
  }));
if (import.meta.hot?.data) import.meta.hot.data.themeRegistered = true;

export const diffOptions = {
  diffIndicators: "classic",
  lineDiffType: "word-alt",
  overflow: "wrap",
  theme,
  themeType: "dark",
  unsafeCSS: `
:host {
  --diffs-bg: #1a1b26;
  --diffs-addition-color-override: #3fb950;
  --diffs-deletion-color-override: #f85149;
  --diffs-fg-number-override: #d6ddf9;
  --diffs-fg-number-addition-override: #d6ddf9;
  --diffs-fg-number-deletion-override: #d6ddf9;
  --diffs-bg-context-override: #1a1b26;
  --diffs-bg-context-gutter-override: #1a1b26;
  --diffs-bg-separator-override: #1f3a5f;
  --diffs-bg-addition-emphasis-override: #264e33;
  --diffs-bg-deletion-emphasis-override: #5f2c31;
  --diffs-font-family: "Hack Nerd Font Mono", ui-monospace, monospace;
  --diffs-font-size: var(--om-diff-font-size, 12px);
  --diffs-line-height: var(--om-diff-line-height, 20px);
}
[data-line-type="change-addition"] { --diffs-computed-diff-line-bg: #1f302b; }
[data-line-type="change-deletion"] { --diffs-computed-diff-line-bg: #35212a; }
[data-line-type="change-addition"]:where([data-gutter-buffer], [data-column-number]) { --diffs-computed-diff-line-bg: #264e33; }
[data-line-type="change-deletion"]:where([data-gutter-buffer], [data-column-number]) { --diffs-computed-diff-line-bg: #5f2c31; }
[data-column-number] { color: #d6ddf9 !important; padding-inline: 1ch !important; text-align: center; }
[data-gutter] [data-column-number], [data-gutter] [data-gutter-buffer] { border-inline-end: 0 !important; }
[data-indicators="classic"] [data-line] { padding-inline-start: 3ch; }
[data-indicators="classic"] [data-line][data-line-type="change-addition"]::before,
[data-indicators="classic"] [data-line][data-line-type="change-deletion"]::before { color: #d6ddf9 !important; left: 1ch; }
[data-separator="line-info"], [data-separator="line-info"] [data-separator-wrapper],
[data-separator="line-info"] [data-separator-content], [data-separator="line-info"] [data-expand-button] { color: #7aa2f7; }
[data-content-buffer] { background-color: #222431; background-image: none; }
[data-gutter-buffer="buffer"] { --diffs-line-bg: #222431; }
[data-line], [data-line] * { -webkit-user-select: text !important; user-select: text !important; }
[data-diff-span], [data-diff-span] span { color: #d6ddf9 !important; }
`,
} satisfies GitDiffOptions;
