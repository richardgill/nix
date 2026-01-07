---
name: issue-management
description: Create, list, and manage issues in thoughts/shared/issues/. Use when users ask to find issues, create issues, list tasks, show progress, complete issues, or organize work. Trigger phrases include "find the issue", "create an issue", "what issues", "list issues", "show progress", "mark as done", "complete the issue", "next issue", "current issues", or any task/issue tracking request.
---

# Issue Management

Manage the project's issue tracking in `thoughts/shared/issues/`.

## Issue & Plan Storage

Issues and plans are tracked in `thoughts/shared/issues/` with numbered phases:

```
thoughts/shared/issues/
├── 10-phase-name/           # Single issue = flat folder
│   └── plan.md
├── 20-another-phase/
│   ├── plan.md
│   └── design.md          # Optional
├── 30-multi-issue-phase/    # Multiple parallel issues = nested
│   ├── feature-a/
│   │   ├── plan.md
│   │   └── design.md
│   └── feature-b/
│       └── plan.md
└── done/                    # Completed issues moved here
```

**Conventions:**
- **Single issue phase** → `NN-phase-name/` (flat)
- **Multi-issue phase** → `NN-phase/issue-name/` (nested, all parallel)
- **Gaps in numbers** (10, 20...) = room to insert phases later
- Each issue has `plan.md` + optional `design.md`
- **Completed issues** → move to `done/`

**Workflow:**
1. Work through phases in order (10 → 20 → 30...)
2. Within a phase folder, pick any issue - they're independent
3. Read issue's `plan.md` for scope

## Commands

### List Issues
Show current issues organized by phase:
```bash
ls -d thoughts/shared/issues/*/ 2>/dev/null | grep -v done/
```

### Create Issue

1. Determine the phase number (check existing phases, use gaps)
2. Create the folder structure:
   - Single issue: `thoughts/shared/issues/NN-issue-name/`
   - Part of multi-issue phase: `thoughts/shared/issues/NN-phase/issue-name/`
3. Optionally create `plan.md` with scope (in/out) and implementation details
4. Optionally create `research.md` for design notes

### Complete Issue

When an issue is fully implemented and verified:
```bash
mkdir -p thoughts/shared/issues/done
mv thoughts/shared/issues/<path-to-issue> thoughts/shared/issues/done/
```

### Show Progress
```bash
echo "=== Active ===" && ls -d thoughts/shared/issues/*/ 2>/dev/null | grep -v done/ | wc -l
echo "=== Done ===" && ls -d thoughts/shared/issues/done/*/ 2>/dev/null | wc -l
```

$ARGUMENTS
