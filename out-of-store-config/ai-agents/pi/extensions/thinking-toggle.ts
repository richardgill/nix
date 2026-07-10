import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const toggleThinkingLevel = (pi: ExtensionAPI) => {
	const current = pi.getThinkingLevel();
	const next = current === "xhigh" ? "high" : "xhigh";
	pi.setThinkingLevel(next);
	return next;
};

export default function (pi: ExtensionAPI) {
	pi.registerShortcut("shift+tab", {
		description: "Toggle thinking high/xhigh",
		handler: (ctx) => {
			const level = toggleThinkingLevel(pi);
			ctx.ui.notify(`Thinking level: ${level}`, "info");
		},
	});

	pi.registerCommand("toggle-thinking", {
		description: "Toggle thinking between high and xhigh",
		handler: (_args, ctx) => {
			const level = toggleThinkingLevel(pi);
			ctx.ui.notify(`Thinking level: ${level}`, "info");
		},
	});
}
