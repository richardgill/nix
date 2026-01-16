# Pi Skills

Skills are on-demand capability packages that the agent loads when needed.

## Structure

Each skill is a directory with a `SKILL.md` file:

```
my-skill/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Helper scripts (bash, python, node)
├── references/           # Detailed docs loaded on-demand
└── assets/               # Templates, images, etc.
```

## SKILL.md Format

```markdown
---
name: my-skill
description: What this skill does and when to use it. Be specific.
---

# My Skill

## Setup

Run once before first use:
\`\`\`bash
cd /path/to/skill && npm install
\`\`\`

## Usage

\`\`\`bash
./scripts/process.sh <input>
\`\`\`

## Workflow

1. First step
2. Second step
3. Third step
```

## Frontmatter Requirements

- `name`: Required. Max 64 chars. Lowercase a-z, 0-9, hyphens only. Must match parent directory name.
- `description`: Required. Max 1024 chars. What the skill does and when to use it.

## Usage

Skills are automatically discovered and loaded on-demand when the agent decides a task matches the description. You can also invoke them directly with `/skill:name`.

## Skill Repositories

- [Anthropic Skills](https://github.com/anthropics/skills) - Official skills for document processing
- [Pi Skills](https://github.com/badlogic/pi-skills) - Web search, browser automation, Google APIs

## Documentation

See `/home/rich/code/reference-repos/pi-mono/packages/coding-agent/docs/skills.md`
