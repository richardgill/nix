## Code style

- Main functions should show the “what”; extract the “how” only when the helper name adds clarity.
- Prefer orchestration that fits on 1.5 screen heights; if it grows, extract cohesive chunks rather than scattering a linear idea.
- Avoid tiny one-use helpers: extract only when it makes code clearer, not just shorter.
- Functions should fit in your head; use <8 lines ideal, 8-15 acceptable, 15+ review as a heuristic, but not a mandate.
- Check invariants with guards at the top of functions; return or throw if they fail.
- Push side effects to the edges: fetch, transform (pure), emit. Don't interleave I/O with logic.
- Pre-existing comments: Leave pre-existing comments (from before this PR) intact when editing code
- New comments: Do NOT introduce new comments unless it's a truly exceptional case / noteworthy. You may override this rule if the user requests it explicitly.
- Unless explicitly asked, prefer clean breaks over backwards compatibility; if unsure, ask instead of hedging with legacy paths, shims, or fallback layers.

### TypeScript / JavaScript

- Always use `const myFunc = () => ...` in typescript.
- Use `export const` and only use `export default` if it's needed by a library, framework or existing convention in the code
- Always define functions at the root scope, do not nest function definitions in functions unless really you need to
- Always use TypeScript `type` in favor of `interface` unless you must use interface (or it follows conventions in the code)
- Prefer object arguments when there are too many positional args, or when names make the call site clearer; keep positional args when the order is conventional or obvious.
- Favor `??` over `||` where it makes sense.
- Never use nullish coalescing assignment (`??=`).
- Favor `Boolean(blah)` over `!!blah`
- Do not use: `while`, `switch`, `continue`, `break`, `in`, `delete` keywords except if there is good reason to do so
- New comments: Always single line // comments
- Existing comments: Keep comment style that was there before
- Prefer immutable, functional code where possible. (If it's neater to mutate, this is fine)

## Dev environment

- I work on Mac or NixOS and the filesystem is case sensitive
- To run software without installing it, prefer `nix shell nixpkgs#<pkg> -c <cmd>`; fall back to `mise` for specific tool versions.
- Prefer not to use npx or bunx for anything where package.json has it. Rely on pnpm exec
- You can `gh repo clone` helpful repos to `~/code/reference-repos/` and then explore them to figure out how things work.
- Use `~/code/noisy-files/` for persistent bulky scratch files or generated/reference material that should not live in a repo.
- Only use `/tmp/` for truly ephemeral files that do not need to survive reboot.

## Workflow

- Only do git commits when I explicitly ask.
- PR descriptions should be empty by default, unless asked otherwise.
- Always read PR desc first before editing it so you can amend.
- "Manual testing" means running commands to test something like a human would. Do it by default unless asked otherwise.
- Watch gh checks by running `gh pr checks --watch --fail-fast || gh run view --log-failed | tail -n 200` in background
- When the user asks to open/show/launch a URL or link on their machine, use: `open '<url>'`. If ambiguous, ask: “Should I just open it for you, or should I inspect/interact with it?”
- To retrieve page content from a URL, use kagi ask-page <url> "<question>".

## Overlay and scratch work

There is a gitignored `overlay/` folder in all repos:

`overlay/branch` use this by default for your temporary work and experimentation. When I say `overlay` assume this is what I mean by default.
`overlay/branches` other branches temporary work and experimentation. This is ignored by default in ripgrep; if you cannot find older branch scratch, search it explicitly with `rg -u <pattern> overlay/branches`.
Avoid putting large, generated, vendored, or external trees in overlay/. Use `~/code/noisy-files/` or `~/code/reference-repos/` instead.

## Response conventions

- When referencing files, use repo-relative paths: `./folder/file.txt`, `./folder/file.txt:5`, or `./folder/file.txt:4-7`.
- Prefer: sketch shape → confirm → implement. Get agreement on structure / APIs / "interfaces" / code seams before implementation details.
- If I mention “parrot”, it means I'm going to take your response -> edit it -> send it back to you. Be sure to optimize message structure so that it's in a format where it just includes the decisions / requirements / main points so I can modify it easily.

### Brevity and response style

Default to terse, high-signal responses.

Start with the answer. No preamble.
Use at most 4 short bullets or 2 short paragraphs unless the user asks for more.
Do not restate the question, recap obvious context, or add filler, hedging, or motivational language.
Include only what is needed to act now: the decision, key rationale, commands, paths, risks, and next step.

Expand only when the user explicitly asks or when brevity would risk correctness or safety.
If you must exceed these limits for correctness, say so in one short sentence and continue briefly.

### Proposed Code-change review format

For quick comprehension you must present code changes outside-in, showing new code / code changes in context with surrounding existing code:
You need to show me the code as a 'sketch' of the 'shape' of the code whilst being brief.

What to include:

- The high level 'story' of function calls and high-level control flow.
- Show the flow of the code as if I was reading the usages, so I can understand the structure that a first time reader of the code would see. But omit the
 technical details from the code, it's a sketch.
- I care about the functions (including signatures, put them as comments above the function usages). Use TypeScript imports at the top to show file paths, file status, and function status.
- Relevant code context around the changes so I can understand how our changes and additions fit into the existing code

What **not** to include:
- Internal implementation details that are obvious, by default omit the code inside of functions themselves unless it's important
- Too much information - you need to maximize comprehension so I can review proposed changes quickly

## SSH to local client with reverse tunnel

To check whether this is an SSH session and the reverse tunnel to the local client is available run the `tunnel-check` command.

If the reverse tunnel is available, use `tunnel-exec <command>` to run one-off commands on the local client.

Move files between machines:
```bash
# remote -> local client
scp -P ${TUNNEL_PORT:-1999} ./file localhost:~/Downloads/
scp -P ${TUNNEL_PORT:-1999} ./screenshot.png localhost:~/Screenshots/

# local client -> remote
scp -P ${TUNNEL_PORT:-1999} localhost:~/Downloads/file ./
scp -P ${TUNNEL_PORT:-1999} localhost:~/Screenshots/screenshot.png ./
```

