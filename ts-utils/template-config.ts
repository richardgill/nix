const DOT_FILES = "modules/home-manager/dot-files"

// Directories to transform (will recursively process .hbs templates and copy static files)
export const directories = [
  "ai-agents",
  "alacritty",
  "cmus",
  "firefox",
  "ghostty",
  "mise",
  "ripgrep",
  "shell",
  "tmux",
  "zsh",
]

// Root-level template files (not in subdirectories)
export const rootTemplates = ["zprofile.hbs", "zshenv.hbs"]

export const DOT_FILES_PATH = DOT_FILES
