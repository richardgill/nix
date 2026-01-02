---
name: oracle
description: Invoke Codex (GPT-5) with high reasoning for deep analysis, debugging, architecture, or security reviews
---

# Oracle

Escalate to Codex (GPT-5.2) with high reasoning effort for problems requiring deeper analysis. Use for:
- Complex debugging with elusive bugs
- Architectural decisions and tradeoffs
- Security audits and vulnerability analysis
- Code review requiring deep reasoning

## Main command

Run Codex in non-interactive mode with high reasoning:

```bash
codex exec --sandbox read-only -c model_reasoning_effort='"high"' "$PROMPT"
```

Where `$PROMPT` is your analysis request. Codex bundles relevant context from your repo automatically.

## Reasoning effort

- `high` — deep reasoning, ~3x tokens, best for complex problems (oracle default)
- `medium` — balanced (codex default)
- `low` — fast, minimal thinking

## Options

- `--sandbox read-only` — analyze without modifying files (recommended)
- `--sandbox workspace-write` — allow file modifications if needed
- `-o /tmp/oracle-response.md` — save response to file
- `-C <dir>` — run in specific directory

## Guidelines

- Oracle is **read-only** — analyzes but doesn't modify code
- Treat outputs as advisory — verify against codebase
- Use for genuinely complex problems (not routine tasks)
- High reasoning uses ~3x tokens but thinks deeper

## Examples

```bash
# Debug intermittent auth issue
codex exec --sandbox read-only -c model_reasoning_effort='"high"' \
  "The auth flow fails intermittently. Check src/auth/ for race conditions."

# Architectural review
codex exec --sandbox read-only -c model_reasoning_effort='"high"' \
  "Review src/api/ data flow and suggest improvements for scalability."

# Security audit
codex exec --sandbox read-only -c model_reasoning_effort='"high"' \
  "Audit src/handlers/ for OWASP top 10 vulnerabilities."
```

$ARGUMENTS
