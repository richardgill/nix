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
  "tmux",
  "zsh",
]

// Root-level template files (not in subdirectories)
export const rootTemplates = ["zprofile.hbs", "zshenv.hbs"]

// Agent configuration - single source of truth for all AI agents
export const agents = {
  claude: {
    sharedSkills: true,
    sharedAgents: true,
    commands: true,
    commandsFolder: "commands",
  },
  codex: {
    sharedSkills: true,
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
  },
  ampcode: {
    sharedSkills: false,
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
  },
  opencode: {
    sharedSkills: false,
    sharedAgents: false,
    commands: true,
    commandsFolder: "command",
  },
} as const

export type AgentName = keyof typeof agents

export const DOT_FILES_PATH = DOT_FILES
