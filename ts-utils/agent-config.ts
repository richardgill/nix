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

const isCodexPro = false;
const mediumModel = isCodexPro ? "gpt-5.3-codex-spark" : "gpt-5.3-codex";
const mediumProvider = `openai-codex/${mediumModel}`;
const webSearchSkills = ["web-search-exa", "web-search-kagi"];
const activeWebSearchSkill = "web-search-kagi";
const inactiveWebSearchSkills = webSearchSkills.filter(
  (skill) => skill !== activeWebSearchSkill,
);

export const agents = {
  claude: {
    sharedSkills: true,
    excludeSkills: webSearchSkills,
    sharedAgents: true,
    commands: true,
    commandsFolder: "commands",
    binary: "cl",
    modelFamily: "anthropic",
  },
  codex: {
    sharedSkills: true,
    excludeSkills: webSearchSkills,
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
    binary: "codex",
    modelFamily: "openai",
  },
  ampcode: {
    sharedSkills: true,
    excludeSkills: webSearchSkills,
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
    binary: "amp",
    modelFamily: "openai",
  },
  opencode: {
    sharedSkills: true,
    excludeSkills: inactiveWebSearchSkills,
    sharedAgents: false,
    commands: true,
    commandsFolder: "command",
    binary: "oc",
    modelFamily: "anthropic",
  },
  pi: {
    sharedSkills: true,
    excludeSkills: inactiveWebSearchSkills,
    sharedAgents: false,
    commands: false,
    commandsFolder: "",
    binary: "pi",
    modelFamily: "openai",
    presets: {
      low: {
        provider: "openai-codex",
        model: mediumModel,
        providerModel: mediumProvider,
        thinkingLevel: "low",
      },
      medium: {
        provider: "openai-codex",
        model: mediumModel,
        providerModel: mediumProvider,
        thinkingLevel: "medium",
      },
      high: {
        provider: "openai-codex",
        model: "gpt-5.4",
        providerModel: "openai-codex/gpt-5.4",
        thinkingLevel: "high",
      },
      xhigh: {
        provider: "openai-codex",
        model: "gpt-5.4",
        providerModel: "openai-codex/gpt-5.4",
        thinkingLevel: "xhigh",
      },
    },
  },
} as const satisfies Record<string, AgentConfig>;

export type AgentName = keyof typeof agents;
