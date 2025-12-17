---
name: creating-plans
description: Use when design is complete and you need detailed implementation tasks for engineers with zero codebase context - creates comprehensive implementation plans with exact file paths, complete code examples, and verification steps assuming engineer has minimal domain knowledge
---

# Creating Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. 

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the creating-plans skill to create the implementation plan."

**Save plans to:** `scratch/plans/YYYY-MM-DD-<feature-name>.md`

Start by creating a planning todo list (TodoWrite):

- [ ] Read provided documents & Explore the relevant code
- [ ] Use the codebase-pattern-finder agent to identify similar code
- [ ] If you have questions or are unsure about anything please ask for clarification until everything is resolved
- [ ] Write the plan to disk
- [ ] Read the plan again and review it based on the plan criteria laid out here.
- [ ] Reply to user with the plan summary 


## Plan Document Header

**Every plan MUST start with a Plan summary header:**

```markdown
**Plan summary**

- A 150 line explanation of the plan that I can send to my colleague. 
- Motivation: Why are we doing this.
- It should include key decisions which may be preference and could have gone the other way. 
- Which files will be affected and how.
- Code snippets showing usage patterns, signatures, and integration points.
- Include your feedback loop / check you will run to confirm your implement is good / working
  -[pnpm|bun] run local-ci` is a good option,
  - Any other commands you can run to check your work? Curl? node -e? 
- If it needs manually testing include those commands here for me to review.

---

** Full plan **

<full plan goes here>
```
## Full Plan

- Include all files to change with line numbers:
- The code that will go in that file
- Each step is one bite sized action (2-3 minutes)
- Stucture your plan as a check list using [ ]

## Remember
- {{> usage-signature-flow }}
- {{> sketch-first }}
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits



