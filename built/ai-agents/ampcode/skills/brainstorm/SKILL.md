---
name: brainstorm
description: Refines rough ideas into fully-formed designs through collaborative questioning, alternative exploration, and incremental validation. Use before writing code or implementation plans.
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

You can use the research-web skill to search the web

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
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

**Documentation:**
- Use the Skill(issues) to write the validated design to `./issues/<path-to-issue>/design.md`

- Ask: "Want to create a plan or begin implementation?"
- Create detailed implementation plan in the same issue folder

## Key Principles

- Prefer: sketch shape → confirm → implement. Get agreement on structure before details.

- For quick comprehension you must present code changes outside-in, showing new code / code changes **in context** with surrounding existing code:
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




- Implementation: the "how" (often skippable unless important)
- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
