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

export type WebSearchProvider = {
  id: string;
  displayName: string;
  skill: string;
  searchCommand: string;
  fetchCommand: string;
  focusedFetchCommand: string;
  quickAnswerCommand: string;
  prerequisites: readonly string[];
};

export type AgentConfig = {
  sharedSkills: boolean;
  excludeSkills?: readonly string[];
  builtInWebSearch: boolean;
  webSearchName: string;
  webFetchName: string;
  sharedAgents: boolean;
  commands: boolean;
  commandsFolder: string;
  binary: string;
  modelFamily: ModelFamily;
  presets?: AgentPresets;
};

const mediumModel = "gpt-5.6-sol";
const mediumProvider = `openai-codex/${mediumModel}`;
const highModel = "gpt-5.6-sol";
const highProvider = `openai-codex/${highModel}`;
const webSearchSkill = "web-search";
const webSearchProviders = {
  exa: {
    id: "exa",
    displayName: "Exa",
    skill: webSearchSkill,
    searchCommand: 'exa-search.js "<query>"',
    fetchCommand: "exa-contents.js <url> --text",
    focusedFetchCommand: 'exa-contents.js <url> --highlights "<query>"',
    quickAnswerCommand: 'exa-search.js "<question>" --num 5',
    prerequisites: [
      "`exa-search.js`, `exa-contents.js`, and `exa-similar.js` must be available in PATH.",
      "The Exa API key must be configured.",
    ],
  },
  kagi: {
    id: "kagi",
    displayName: "Kagi",
    skill: webSearchSkill,
    searchCommand: 'kagi search "<query>"',
    fetchCommand: 'kagi ask-page <url> "<question>"',
    focusedFetchCommand:
      'kagi ask-page <url> "Extract excerpts relevant to: <query>"',
    quickAnswerCommand: 'kagi quick "<question>"',
    prerequisites: [
      "`kagi` must be installed and available in PATH.",
      "Run `kagi auth` once before first use.",
    ],
  },
} as const satisfies Record<string, WebSearchProvider>;
export const activeWebSearchProvider = webSearchProviders.kagi;
const webSearchSkillExclusion = [activeWebSearchProvider.skill];

export const agents = {
  claude: {
    sharedSkills: true,
    excludeSkills: webSearchSkillExclusion,
    builtInWebSearch: true,
    webSearchName: "WebSearch",
    webFetchName: "WebFetch",
    sharedAgents: true,
    commands: true,
    commandsFolder: "commands",
    binary: "cl",
    modelFamily: "anthropic",
  },
  codex: {
    sharedSkills: true,
    builtInWebSearch: false,
    webSearchName: activeWebSearchProvider.displayName,
    webFetchName: activeWebSearchProvider.fetchCommand,
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
    binary: "codex",
    modelFamily: "openai",
  },
  ampcode: {
    sharedSkills: true,
    builtInWebSearch: false,
    webSearchName: activeWebSearchProvider.displayName,
    webFetchName: activeWebSearchProvider.fetchCommand,
    sharedAgents: false,
    commands: true,
    commandsFolder: "commands",
    binary: "amp",
    modelFamily: "openai",
  },
  opencode: {
    sharedSkills: true,
    excludeSkills: webSearchSkillExclusion,
    builtInWebSearch: true,
    webSearchName: "kagi",
    webFetchName: "webfetch",
    sharedAgents: false,
    commands: true,
    commandsFolder: "command",
    binary: "oc",
    modelFamily: "anthropic",
  },
  pi: {
    sharedSkills: true,
    excludeSkills: ["diff", "pr-diff"],
    builtInWebSearch: false,
    webSearchName: activeWebSearchProvider.displayName,
    webFetchName: activeWebSearchProvider.fetchCommand,
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
        model: highModel,
        providerModel: highProvider,
        thinkingLevel: "high",
      },
      xhigh: {
        provider: "openai-codex",
        model: highModel,
        providerModel: highProvider,
        thinkingLevel: "xhigh",
      },
    },
  },
} as const satisfies Record<string, AgentConfig>;

export type AgentName = keyof typeof agents;
