export const agents = {
  claude: {
    sharedSkills: true,
    excludeSkills: ["web-search"],
    sharedAgents: true,
    commands: true,
    commandsFolder: "commands",
    binary: "cl",
  },
  codex: {
    sharedSkills: true,
    excludeSkills: ["web-search"],
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
    binary: "codex",
  },
  ampcode: {
    sharedSkills: true,
    excludeSkills: ["web-search"],
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
    binary: "amp",
  },
  opencode: {
    sharedSkills: true,
    sharedAgents: false,
    commands: true,
    commandsFolder: "command",
    binary: "oc",
  },
  pi: {
    sharedSkills: true,
    sharedAgents: false,
    commands: false,
    commandsFolder: "",
    binary: "pi",
  },
} as const;

export type AgentName = keyof typeof agents;
