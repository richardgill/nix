---
name: create-plan
description: Create implementation plans with human-readable summaries.
metadata:
  pi:
    subProcess: false
    model: openai-codex/gpt-5.2
    thinkingLevel: xhigh

---

# Creating Plans

## Overview

Write plans optimized for human review:

## Plan Document Structure

A plan has two sections:

### Plan summary for human review at the top

The summary tells a story that a human engineer can follow in <150 lines. You must show the *shape* of the changes so the plan reviewer can spot issues early. The goal of the plan is to help the human understand what the high level plan is without an overwhelming amount of information.

The plan summary may include the following:

- Reassert briefly your understanding of what the goal of the plan is (so that the human can verify that you understand)
- The information that you gathered that the human likely doesn't already know which impacted the direction of the plan
- The shape of the code after the plan is implemented, so they can verify the design is agreeable to them. Use the usage-signature-flow format below.
- Decisions you made (possibly implicitly) that have a valid (>40% chance of being valid) other options.
- Assumptions you made that could be incorrect (less than 85% certain)
- Automated strategy that an agent will use to check changes fulfill the goals of the plan. Keep them simple, they should be as e2e as possible. They could involve writing a script in scratch/ to invoke functionality into a verifiable string that an agent can review.

#### Usage signature flow
For quick comprehension you must present code changes outside-in, showing new code / code changes **in context** with surrounding existing code:
You need to show me the code as a 'sketch' of the 'shape' of the code whilst being brief.

What to include:

- The high level 'story' of function calls and high-level control flow.
- Show the flow of the code as if I was reading the usages, so I can understand the structure that a first time reader of the code would see. But omit the
 technical details from the code, it's a sketch.
- I care about the functions (including signatures, put them as comments above the function usages). Use TypeScript imports at the top to show file paths, file status, and function status.
- Relevant code context around the changes so I can understand how our changes and additions fit into the existing code

What **not** to include:
- Internal implementation details that are obvious, by default omit the code inside of functions themselves unless it's important
- Too much information - you need to maximize comprehension so I can review the plan quickly




<example>
## Plan Summary

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

- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions

Start by creating a planning todo list:

Collect context information:

- [ ] Read any provided documents / context & Explore the relevant code
- [ ] Use the codebase-pattern-finder skill to identify similar code
- [ ] If you have questions or are unsure about anything please ask for clarification until everything is resolved

Draft the plan and iterate:

- [ ] Draft a full plan (summary + implementation) and write it to disk using the "issues skill" using the "issues skill"
- [ ] Read the plan again and review it based on the plan criteria laid out here. Focus on how easy it is for human to digest and review the plan so they can give feedback on any potential issues early on.

**End with:** The verbatim plan summary directly in the chat, always tell the user the exact command to run:
Would you like to create a worktree using worktree skill to start working on this issue?
`/implementing-plans ./issues/<path-to-issue>/plan.md`
