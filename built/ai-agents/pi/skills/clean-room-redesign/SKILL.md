---
name: clean-room-redesign
description: Plans and oversees a clean-room rewrite from existing behavior. Use for greenfield redesigns and aggressive legacy replacements.
---

# Clean-room redesign

Agree on the entry point, rewrite boundary, locked interfaces, allowed upstream exceptions, and explicit exclusions before designing. Start by making it explict where / what they are.

Inspect existing code only to extract observable behavior. Write requirements without mentioning current files, frameworks, abstractions, or implementation patterns (unless they're locked in by the design).

Save requirements and confirmed decisions to `./overlay/branch/current-functional-requirements.md`. Remove superseded decisions instead of documenting compatibility paths.

Discuss one concept at a time. Explain directly without analogies. Separate required behavior from incidental complexity and recommend the simplest viable choice.

Before implementation, spawn a fresh high-reasoning agent with the complete requirements inline. Explicitly forbid it from reading, listing, searching, or inferring from the repository, git history, tests, manifests, or generated files.

Require the clean-room design to include:

- Architecture and ownership.
- A file tree with a responsibility comment beside every file.
- Exported production function signatures and important types.
- Outside-in call flows.
- A small high-value test plan.
- Decisions requiring confirmation.

Save the reviewed design to `./overlay/branch/clean-room-design.md`.

Do not accept delegated output uncritically. Check it against every requirement, the rewrite boundary, lifecycle ownership, cleanup, failure behavior, and previously rejected complexity.

Present the final design as the actual call story from retained entry point through orchestration, domain logic, transports, effects, and shutdown.

Each production file should begin with a terse 2-4 line comment explaining its context, responsibility, and reason for existing. Add further comments only for non-obvious domain invariants.

Prefer explicit domain models for tricky pure behavior that benefits from focused table-driven tests.

Prefer a few e2e tests through public boundaries. Avoid duplicating coverage across layers. Plan manual browser testing before implementation.

Implement in sequential cohesive phases using fresh agents. Do not run overlapping phases against the same files.

Give implementation agents exact scope, exclusions, approved documents, aggressive deletion instructions, and required checks. They may inspect the existing code.

After every phase, inspect the diff, compare it with the approved design, search for obsolete code and terminology, and run targeted tests.

The parent agent owns correctness. Delegates do not make unapproved product or architecture decisions.

When user input is required, stop and use the notify skill.

Finish with full local CI, manual browser testing, obsolete-code cleanup, and a final design-to-implementation check.
