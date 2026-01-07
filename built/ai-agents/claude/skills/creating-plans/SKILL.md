---
name: creating-plans
description: |
  This skill creates structured implementation plans with human-readable summaries.
  Triggers: "create a plan", "make a plan", "write a plan", "plan this feature",
  "plan how to implement", "break this down", "spec this out", "design this change".
  Creates plans with diagrams, code examples, and verification steps.
  Not for executing plans (use implementing-plans) or brainstorming (use brainstorming).
---

# Creating Plans

## Overview

Write plans optimized for human review:

## Plan Document Structure

A plan has two sections:

### Plan summary for human review at the top

The summary tells a story the reviewer can follow in <150 lines. Not a file list - show the *shape* of the change to review the plan and spot issues early.

**Structure:**
1. **Requirements** - Brief restatement with enough precision to be clear
2. **How it works today** - Diagram showing current flow (builds shared context)
3. **The change** - Diagram showing new flow + code in context. Present code changes outside-in, showing new code **in context** with surrounding existing code:

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

4. **Verification** - Always include `local-ci.sh` + manual testing steps
5. **Testing** - Match existing test patterns. List test files to add/update, then key cases to cover (edge cases, error states, happy path). Give confidence the plan has testing covered.

**Guidelines:**
- Show code in context - what's above and below, not floating snippets
- Only mention alternatives if they were genuinely considered and could have gone either way
- Don't pad with fake tradeoffs or invented alternatives
- Don't list files separately if the diagram already shows them
- Don't condescend ("Clarified with user:") - just state the decisions

<example>
## Plan Summary

### Requirements

Add autosave to the document editor.

- Save triggers 2 seconds after user stops typing
- Status indicator shows: "Saving..." during save, "Saved" after success
- Existing manual Save button remains (some users prefer explicit control)
- Save on tab/window blur (don't lose work if user switches away mid-sentence)

### How It Works Today

```
Editor.tsx → onChange → local state only
                ↓
           Save button → documentService.save() → shows toast
```

Changes live in component state until explicit save.

### The Change

```
Editor.tsx → onChange → local state + debounced save (2s)
                              ↓
                        documentService.save()
                              ↓
                        status indicator: "Saving..." → "Saved"
```

```typescript
// Editor.tsx
function Editor({ docId }: Props) {
  const [content, setContent] = useState('')
  const saveStatus = useAutosave(content, ...)        // ← new

  return (
    <div>
      <StatusIndicator status={saveStatus} />         {/* ← new */}
      <TextArea value={content} onChange={setContent} />
      <Button onClick={handleSave}>Save</Button>      {/* stays */}
    </div>
  )
}
```

Debounce logic extracted to `useAutosave` hook.


### Verification

```bash
local-ci.sh
# manual: type in editor, wait 2s, refresh page, confirm content persisted
# manual: disconnect network, type, confirm error appears
```

### Testing

Existing tests use React Testing Library. Add:
- `useAutosave.test.ts` - unit tests for debounce timing and save calls
- Update `Editor.test.tsx` - verify status indicator renders correctly
- `editor.e2e.ts` - type in editor, wait for "Saved" indicator, refresh and verify content persisted

Key cases: debounce resets on new keystroke, save triggers on blur, network error shows error state, rapid typing doesn't spam API, status clears after timeout, ...
</example>

### Plan implementation details

```
## Plan implementation instructions

- Which files will be affected and how.
- Include all files to change with line numbers:
- The code that will go in that file
- Each step is one bite sized action (2-3 minutes)
- Structure your plan as a check list using [ ]
- Complete code in plan (not "add validation")

Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD.

```

## Making your plan

**Announce at start:** "I'm using the creating-plans skill to create the implementation plan."

You must surface any genuine / important questions you have using multichoice questions.

- Prefer multiple choice questions when possible using AskUserQuestion tool, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions

Start by creating a planning todo list:

Collect context information:

- [ ] Read any provided documents / context & Explore the relevant code
- [ ] Use the codebase-pattern-finder agent to identify similar code
- [ ] If you have questions or are unsure about anything please ask for clarification until everything is resolved

Draft the plan and iterate:

- [ ] Draft a full plan (summary + implementation) and write it to disk using the "issues skill" using the "issues skill"
- [ ] Read the plan again and review it based on the plan criteria laid out here. Focus on how easy it is for human to digest and review the plan so they can give feedback on any potential issues early on. ultrathink on this step an iterate until you're happy with the plan.
- [ ] Run the code-reviewer agent to review this plan and the code within it. Use the feedback to improve the plan. If necessary go back to the previous todo and continue iterating on the plan.
- [ ] Run `sed -n '1,/^## Plan implementation/p' <plan-file> | head -n -1` to output the human-readable summary

**End with by replying to user with:**
```
ctrl-o to see human readable plan verbatim
Would you like to create a worktree to start working on this issue?
/implement-plan thoughts/shared/issues/<path-to-issue>/plan.md
```
