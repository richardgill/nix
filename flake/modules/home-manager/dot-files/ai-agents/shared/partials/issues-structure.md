## Issue & Plan Storage

Issues and plans are tracked in `./issues/` with numbered phases:

```
./issues/
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
