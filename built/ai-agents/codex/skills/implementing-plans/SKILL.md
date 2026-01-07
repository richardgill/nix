---
name: implementing-plans
description: |
  Implement technical plans phase-by-phase with verification checkpoints.
  Triggers: "implement this plan", "implement the plan", "execute this plan file",
  "work on the plan", "continue the plan", "pick up where we left off".
  Executes phases with success criteria checks, pauses for manual verification.
  Not for creating plans (use creating-plans) or batch execution (use executing-plans).
---

# Implementing Plans

Implement technical plans with verification - executes phases with success criteria checks, pausing for manual verification between phases.

## Workflow

### 1. Read and Understand the Plan
- Read the entire plan file using the "issues skill".
- Understand the scope, phases, and verification requirements
- Check if there are any prerequisites or blockers

### 2. Pre-Implementation Review
- Immediately add items to your todo list:
  - [ ] "Review implementation with code-reviewer and ask the Skill(oracle) for a code review in parallel"
  - [ ] Consolidate reviews and fix all issues with the reviews

### 3. Execute Each Phase
For each phase in a sub task (sequential):
1. Read the phase requirements carefully
2. Implement the changes
3. Run `local-ci.sh` + other verification steps in plan and fix: until they all succeed 
4. Check off completed items in the plan file itself (use the "issue skill")


### 5. Completion
When all phases are complete:
- Run `local-ci.sh` again
- Summarize all changes made
- Note any follow-up items

## Key Principles

- **Phase by phase** - Complete one phase fully before starting the next use a Sub Task() for each phase (run sequentially)
- **Verify continuously** - Run tests after each significant change
- **Pause for humans** - Don't skip manual verification steps
- **Track progress** - Update the plan file as you go
- **Handle failures gracefully** - Stop, fix, verify, continue

Extra instructions:
$ARGUMENTS
