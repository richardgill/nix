---
name: brainstorming
description: |
  This skill refines rough ideas into fully-formed designs through collaborative questioning
  and exploration. Triggers: "help me brainstorm", "let's think through", "explore options",
  "what are some approaches", "help me design", "think through this with me", "ideate on",
  "what are my options". Use before writing code or plans when the approach is unclear.
  Not for mechanical/routine tasks where the solution is already known.
allowed-tools: WebSearch, WebFetch, Bash, Read, Grep, Glob
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

You can use the search-web agent to search the web

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible using AskUserQuestion tool, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

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

**Documentation:**
- Use the "issues skill" to write the validated design to `thoughts/shared/issues/<path-to-issue>/design.md`

- Ask: "Want to create a plan or begin implementation?"

## Key Principles

- Prefer: sketch shape → confirm → implement. Get agreement on structure before details.

- Present code changes outside-in, showing new code **in context** with surrounding existing code:

1. **Usage & Signature** - reveal the API shape, types, and ergonomics
2. **Flow** - show where new code lands relative to existing code

Example - adding a `formatCurrency` utility:

```ts
// Usage
function formatCurrency(cents: number, currency: 'USD' | 'EUR' | 'GBP'): string

formatCurrency(1999, 'USD');  // "$19.99"
formatCurrency(1999, 'EUR');  // "€19.99"

// Flow - where it lands in existing code
// src/components/ProductCard.tsx
export function ProductCard({ product }: Props) {
  const store = useStore();                          // existing
  const price = formatCurrency(product.cents, ...);  // ← new

  return (
    <div className="card">                           {/* existing */}
      <span className="price">{price}</span>         {/* ← new */}
      <span className="name">{product.name}</span>   {/* existing */}
    </div>
  );
}
```

The reviewer should see what already exists around the new code, not just the new code in isolation.

- Implementation: the "how" (often skippable unless important)
- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
