# Pi Prompt Templates

File-based prompt templates that can be invoked with `/template-name`.

## Format

```markdown
---
description: Review staged git changes
---
Review the staged changes (`git diff --cached`). Focus on:
- Bugs and logic errors
- Security issues
- Error handling gaps
```

Filename (without `.md`) becomes the command name. Description shown in autocomplete.

## Arguments

```markdown
---
description: Create a component
---
Create a React component named $1 with features: $@
```

Usage: `/component Button "onClick handler" "disabled support"`
- `$1` = `Button`
- `$@` or `$ARGUMENTS` = all arguments joined

## Namespacing

Subdirectories create prefixes. `frontend/component.md` → `/component (project:frontend)`

## Locations

- Global: `~/.pi/agent/prompts/*.md`
- Project: `.pi/prompts/*.md`

## Documentation

See "Prompt Templates" section in `/home/rich/code/reference-repos/pi-mono/packages/coding-agent/README.md`
