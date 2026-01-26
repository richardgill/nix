export type ModelFamily = "anthropic" | "openai" | "google";

export type AgentPreset = {
  provider: string;
  model: string;
  providerModel: string;
  thinkingLevel: "low" | "medium" | "high" | "xhigh";
};

export type AgentPresets = {
  low: AgentPreset;
  medium: AgentPreset;
  high: AgentPreset;
  xhigh: AgentPreset;
};

export type AgentConfig = {
  sharedSkills: boolean;
  excludeSkills?: readonly string[];
  sharedAgents: boolean;
  commands: boolean;
  commandsFolder: string;
  binary: string;
  modelFamily: ModelFamily;
  presets?: AgentPresets;
};

export const agents = {
  claude: {
    sharedSkills: true,
    excludeSkills: ["web-search"],
    sharedAgents: true,
    commands: true,
    commandsFolder: "commands",
    binary: "cl",
    modelFamily: "anthropic",
  },
  codex: {
    sharedSkills: true,
    excludeSkills: ["web-search"],
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
    binary: "codex",
    modelFamily: "openai",
  },
  ampcode: {
    sharedSkills: true,
    excludeSkills: ["web-search"],
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
    binary: "amp",
    modelFamily: "openai",
  },
  opencode: {
    sharedSkills: true,
    sharedAgents: false,
    commands: true,
    commandsFolder: "command",
    binary: "oc",
    modelFamily: "anthropic",
  },
  pi: {
    sharedSkills: true,
    sharedAgents: false,
    commands: false,
    commandsFolder: "",
    binary: "pi",
    modelFamily: "openai",
    presets: {
      low: {
        provider: "openai-codex",
        model: "gpt-5.1-codex-max",
        providerModel: "openai-codex/gpt-5.1-codex-max",
        thinkingLevel: "low",
      },
      medium: {
        provider: "openai-codex",
        model: "gpt-5.1-codex-max",
        providerModel: "openai-codex/gpt-5.1-codex-max",
        thinkingLevel: "medium",
      },
      high: {
        provider: "openai-codex",
        model: "gpt-5.2-codex",
        providerModel: "openai-codex/gpt-5.2-codex",
        thinkingLevel: "high",
      },
      xhigh: {
        provider: "openai-codex",
        model: "gpt-5.2",
        providerModel: "openai-codex/gpt-5.2",
        thinkingLevel: "xhigh",
      },
    },
  },
} as const satisfies Record<string, AgentConfig>;

export type AgentName = keyof typeof agents;
