import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import { Container, type SelectItem, SelectList, Text } from "@mariozechner/pi-tui";

type Preset = {
	provider?: string;
	model?: string;
	thinkingLevel?: "off" | "minimal" | "low" | "medium" | "high" | "xhigh";
	tools?: string[];
	instructions?: string;
};

type PresetsConfig = Record<string, Preset>;

type PresetState = {
	presets: PresetsConfig;
	activePresetName?: string;
	activePreset?: Preset;
};

const DEFAULT_TOOLS = ["read", "bash", "edit", "write"];
const DEFAULT_PRESET_NAME = "high";

const createPresetState = (): PresetState => ({
	presets: {},
	activePresetName: undefined,
	activePreset: undefined,
});

const readPresetsFile = (path: string): PresetsConfig => {
	if (!existsSync(path)) {
		return {};
	}

	try {
		const content = readFileSync(path, "utf-8");
		return JSON.parse(content) as PresetsConfig;
	} catch (error) {
		console.error(`Failed to load presets from ${path}: ${error}`);
		return {};
	}
};

const loadPresets = (cwd: string): PresetsConfig => {
	const globalPath = join(homedir(), ".pi", "agent", "presets.json");
	const projectPath = join(cwd, ".pi", "presets.json");

	const globalPresets = readPresetsFile(globalPath);
	const projectPresets = readPresetsFile(projectPath);

	return { ...globalPresets, ...projectPresets };
};

const setActivePreset = (state: PresetState, name: string, preset: Preset): void => {
	state.activePresetName = name;
	state.activePreset = preset;
};

const applyPresetModel = async (
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	name: string,
	preset: Preset,
): Promise<void> => {
	if (!preset.provider || !preset.model) {
		return;
	}

	const model = ctx.modelRegistry.find(preset.provider, preset.model);
	if (!model) {
		ctx.ui.notify(`Preset "${name}": Model ${preset.provider}/${preset.model} not found`, "warning");
		return;
	}

	const success = await pi.setModel(model);
	if (!success) {
		ctx.ui.notify(`Preset "${name}": No API key for ${preset.provider}/${preset.model}`, "warning");
	}
};

const applyPresetThinkingLevel = (pi: ExtensionAPI, preset: Preset): void => {
	if (preset.thinkingLevel) {
		pi.setThinkingLevel(preset.thinkingLevel);
	}
};

const applyPresetTools = (pi: ExtensionAPI, ctx: ExtensionContext, name: string, preset: Preset): void => {
	if (!preset.tools || preset.tools.length === 0) {
		return;
	}

	const allToolNames = pi.getAllTools().map((tool) => tool.name);
	const validTools = preset.tools.filter((tool) => allToolNames.includes(tool));
	const invalidTools = preset.tools.filter((tool) => !allToolNames.includes(tool));

	if (invalidTools.length > 0) {
		ctx.ui.notify(`Preset "${name}": Unknown tools: ${invalidTools.join(", ")}`, "warning");
	}

	if (validTools.length > 0) {
		pi.setActiveTools(validTools);
	}
};

const applyPreset = async (
	pi: ExtensionAPI,
	state: PresetState,
	name: string,
	preset: Preset,
	ctx: ExtensionContext,
): Promise<boolean> => {
	await applyPresetModel(pi, ctx, name, preset);
	applyPresetThinkingLevel(pi, preset);
	applyPresetTools(pi, ctx, name, preset);
	setActivePreset(state, name, preset);
	return true;
};

const buildPresetDescription = (preset: Preset): string => {
	const parts: string[] = [];

	if (preset.provider && preset.model) {
		parts.push(`${preset.provider}/${preset.model}`);
	}
	if (preset.thinkingLevel) {
		parts.push(`thinking:${preset.thinkingLevel}`);
	}
	if (preset.tools) {
		parts.push(`tools:${preset.tools.join(",")}`);
	}
	if (preset.instructions) {
		const truncated =
			preset.instructions.length > 30 ? `${preset.instructions.slice(0, 27)}...` : preset.instructions;
		parts.push(`"${truncated}"`);
	}

	return parts.join(" | ");
};

const updateStatus = (state: PresetState, ctx: ExtensionContext): void => {
	if (state.activePresetName) {
		ctx.ui.setStatus("preset", ctx.ui.theme.fg("accent", `preset:${state.activePresetName}`));
		return;
	}

	ctx.ui.setStatus("preset", undefined);
};

const clearPreset = (pi: ExtensionAPI, state: PresetState, ctx: ExtensionContext): void => {
	state.activePresetName = undefined;
	state.activePreset = undefined;
	pi.setActiveTools(DEFAULT_TOOLS);
	ctx.ui.notify("Preset cleared, defaults restored", "info");
	updateStatus(state, ctx);
};

const notifyPresetActivated = (name: string, ctx: ExtensionContext, note?: string): void => {
	const suffix = note ? ` ${note}` : "";
	ctx.ui.notify(`Preset "${name}" activated${suffix}`, "info");
};

const activatePreset = async (
	pi: ExtensionAPI,
	state: PresetState,
	name: string,
	preset: Preset,
	ctx: ExtensionContext,
	note?: string,
): Promise<void> => {
	await applyPreset(pi, state, name, preset, ctx);
	notifyPresetActivated(name, ctx, note);
	updateStatus(state, ctx);
};

const getPresetNames = (state: PresetState): string[] => Object.keys(state.presets);

const getPresetOrder = (state: PresetState): string[] => getPresetNames(state).sort();

const getPresetStateEntryName = (ctx: ExtensionContext): string | null => {
	const entries = ctx.sessionManager.getEntries();
	const presetEntry = entries
		.filter((entry: { type: string; customType?: string }) => entry.type === "custom" && entry.customType === "preset-state")
		.pop() as { data?: { name?: string } } | undefined;

	return presetEntry?.data?.name ?? null;
};

const getPresetListItems = (state: PresetState): SelectItem[] => {
	const presetNames = getPresetNames(state);
	const items = presetNames.map((name) => {
		const preset = state.presets[name];
		const isActive = name === state.activePresetName;
		return {
			value: name,
			label: isActive ? `${name} (active)` : name,
			description: buildPresetDescription(preset),
		};
	});

	return [
		...items,
		{
			value: "(none)",
			label: "(none)",
			description: "Clear active preset, restore defaults",
		},
	];
};

const showPresetSelector = async (pi: ExtensionAPI, state: PresetState, ctx: ExtensionContext): Promise<void> => {
	const presetNames = getPresetNames(state);
	if (presetNames.length === 0) {
		ctx.ui.notify("No presets defined. Add presets to ~/.pi/agent/presets.json or .pi/presets.json", "warning");
		return;
	}

	const items = getPresetListItems(state);

	const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
		const container = new Container();
		container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));
		container.addChild(new Text(theme.fg("accent", theme.bold("Select Preset"))));

		const selectList = new SelectList(items, Math.min(items.length, 10), {
			selectedPrefix: (text) => theme.fg("accent", text),
			selectedText: (text) => theme.fg("accent", text),
			description: (text) => theme.fg("muted", text),
			scrollInfo: (text) => theme.fg("dim", text),
			noMatch: (text) => theme.fg("warning", text),
		});

		selectList.onSelect = (item) => done(item.value);
		selectList.onCancel = () => done(null);

		container.addChild(selectList);
		container.addChild(new Text(theme.fg("dim", "↑↓ navigate • enter select • esc cancel")));
		container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));

		return {
			render(width: number) {
				return container.render(width);
			},
			invalidate() {
				container.invalidate();
			},
			handleInput(data: string) {
				selectList.handleInput(data);
				tui.requestRender();
			},
		};
	});

	if (!result) {
		return;
	}

	if (result === "(none)") {
		clearPreset(pi, state, ctx);
		return;
	}

	const preset = state.presets[result];
	if (preset) {
		await activatePreset(pi, state, result, preset, ctx);
	}
};

const cyclePreset = async (pi: ExtensionAPI, state: PresetState, ctx: ExtensionContext): Promise<void> => {
	const presetNames = getPresetOrder(state);
	if (presetNames.length === 0) {
		ctx.ui.notify("No presets defined. Add presets to ~/.pi/agent/presets.json or .pi/presets.json", "warning");
		return;
	}

	const cycleList = ["(none)", ...presetNames];
	const currentName = state.activePresetName ?? "(none)";
	const currentIndex = cycleList.indexOf(currentName);
	const nextIndex = currentIndex === -1 ? 0 : (currentIndex + 1) % cycleList.length;
	const nextName = cycleList[nextIndex];

	if (nextName === "(none)") {
		clearPreset(pi, state, ctx);
		return;
	}

	const preset = state.presets[nextName];
	if (preset) {
		await activatePreset(pi, state, nextName, preset, ctx);
	}
};

const handlePresetCommand = async (
	pi: ExtensionAPI,
	state: PresetState,
	args: string,
	ctx: ExtensionContext,
): Promise<void> => {
	const trimmed = args.trim();
	if (!trimmed) {
		await showPresetSelector(pi, state, ctx);
		return;
	}

	const preset = state.presets[trimmed];
	if (!preset) {
		const available = getPresetNames(state).join(", ") || "(none defined)";
		ctx.ui.notify(`Unknown preset "${trimmed}". Available: ${available}`, "error");
		return;
	}

	await activatePreset(pi, state, trimmed, preset, ctx);
};

const applyPresetFlag = async (
	pi: ExtensionAPI,
	state: PresetState,
	ctx: ExtensionContext,
	presetFlag: string | null,
): Promise<boolean> => {
	if (!presetFlag) {
		return false;
	}

	const preset = state.presets[presetFlag];
	if (!preset) {
		const available = getPresetNames(state).join(", ") || "(none defined)";
		ctx.ui.notify(`Unknown preset "${presetFlag}". Available: ${available}`, "warning");
		return true;
	}

	await activatePreset(pi, state, presetFlag, preset, ctx);
	return true;
};

const restorePresetState = (state: PresetState, ctx: ExtensionContext, hasPresetFlag: boolean): boolean => {
	if (hasPresetFlag) {
		return false;
	}

	const presetName = getPresetStateEntryName(ctx);
	if (!presetName) {
		return false;
	}

	const preset = state.presets[presetName];
	if (!preset) {
		return false;
	}

	setActivePreset(state, presetName, preset);
	return true;
};

const applyDefaultPreset = async (
	pi: ExtensionAPI,
	state: PresetState,
	ctx: ExtensionContext,
	hasPresetFlag: boolean,
	hasRestoredPreset: boolean,
): Promise<void> => {
	if (hasPresetFlag || hasRestoredPreset || state.activePresetName) {
		return;
	}

	const preset = state.presets[DEFAULT_PRESET_NAME];
	if (!preset) {
		return;
	}

	await activatePreset(pi, state, DEFAULT_PRESET_NAME, preset, ctx, "(default)");
};

const registerPresetExtensions = (pi: ExtensionAPI, state: PresetState): void => {
	pi.registerShortcut("ctrl+shift+u", {
		description: "Cycle presets",
		handler: async (ctx) => {
			console.log("preset shortcut fired");
			if (ctx.hasUI) {
				ctx.ui.notify("Cycling presets (shortcut)", "info");
			}
			await cyclePreset(pi, state, ctx);
		},
	});

	pi.registerCommand("preset", {
		description: "Switch preset configuration",
		handler: async (args, ctx) => {
			await handlePresetCommand(pi, state, args ?? "", ctx);
		},
	});

	pi.registerFlag("preset", {
		description: "Preset configuration to use",
		type: "string",
	});
};

const registerPresetEvents = (pi: ExtensionAPI, state: PresetState): void => {
	pi.on("before_agent_start", async (event) => {
		if (state.activePreset?.instructions) {
			return {
				systemPrompt: `${event.systemPrompt}\n\n${state.activePreset.instructions}`,
			};
		}
	});

	pi.on("session_start", async (_event, ctx) => {
		state.presets = loadPresets(ctx.cwd);

		const presetFlag = pi.getFlag("preset");
		const flagValue = typeof presetFlag === "string" ? presetFlag : null;
		const hasPresetFlag = Boolean(flagValue);

		await applyPresetFlag(pi, state, ctx, flagValue);
		const hasRestoredPreset = restorePresetState(state, ctx, hasPresetFlag);
		await applyDefaultPreset(pi, state, ctx, hasPresetFlag, hasRestoredPreset);

		updateStatus(state, ctx);
	});

	pi.on("turn_start", async () => {
		if (state.activePresetName) {
			pi.appendEntry("preset-state", { name: state.activePresetName });
		}
	});
};

const presetExtension = (pi: ExtensionAPI): void => {
	const state = createPresetState();
	registerPresetExtensions(pi, state);
	registerPresetEvents(pi, state);
};

export default presetExtension;
