# Pi Extensions

Extensions are TypeScript modules that extend pi's behavior.

## Capabilities

- **Custom tools** - Register tools callable by the LLM
- **Event interception** - Block or modify tool calls, inject context, customize compaction
- **User interaction** - Prompt users via dialogs, notifications
- **Custom UI components** - Full TUI components with keyboard input
- **Custom commands** - Register commands like `/mycommand`
- **Session persistence** - Store state that survives restarts
- **Custom rendering** - Control how tool calls/results appear

## Quick Start

Create `~/.pi/agent/extensions/my-extension.ts`:

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  // React to events
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extension loaded!", "info");
  });

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "bash" && event.input.command?.includes("rm -rf")) {
      const ok = await ctx.ui.confirm("Dangerous!", "Allow rm -rf?");
      if (!ok) return { block: true, reason: "Blocked by user" };
    }
  });

  // Register a custom tool
  pi.registerTool({
    name: "greet",
    label: "Greet",
    description: "Greet someone by name",
    parameters: Type.Object({
      name: Type.String({ description: "Name to greet" }),
    }),
    async execute(toolCallId, params, onUpdate, ctx, signal) {
      return {
        content: [{ type: "text", text: \`Hello, \${params.name}!\` }],
        details: {},
      };
    },
  });

  // Register a command
  pi.registerCommand("hello", {
    description: "Say hello",
    handler: async (args, ctx) => {
      ctx.ui.notify(\`Hello \${args || "world"}!\`, "info");
    },
  });
}
```

## Locations

- Global: `~/.pi/agent/extensions/*.ts` or `~/.pi/agent/extensions/*/index.ts`
- Project: `.pi/extensions/*.ts` or `.pi/extensions/*/index.ts`
- CLI: `--extension <path>` or `-e <path>`

## Use Cases

- Permission gates (confirm before `rm -rf`, `sudo`)
- Git checkpointing (stash at each turn, restore on branch)
- Path protection (block writes to `.env`, `node_modules/`)
- Custom compaction (summarize conversation your way)
- Interactive tools (questions, wizards, custom dialogs)
- Stateful tools (todo lists, connection pools)
- External integrations (file watchers, webhooks, CI triggers)

## Available Imports

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";
import { Text, Component } from "@mariozechner/pi-tui";
```

## Documentation

- Full API reference: `/home/rich/code/reference-repos/pi-mono/packages/coding-agent/docs/extensions.md`
- TUI components: `/home/rich/code/reference-repos/pi-mono/packages/coding-agent/docs/tui.md`
- Examples: `/home/rich/code/reference-repos/pi-mono/packages/coding-agent/examples/extensions/`
