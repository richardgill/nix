import { preset } from "preset";

export default preset({
	presets: {
		medium: {
			provider: "openai-codex",
			model: "gpt-5.3-codex",
			thinkingLevel: "medium",
		},
		high: {
			provider: "openai-codex",
			model: "gpt-5.5",
			thinkingLevel: "high",
		},
	},
	commandName: "preset",
	flagName: "preset",
	cycleShortcut: "ctrl+p",
});
