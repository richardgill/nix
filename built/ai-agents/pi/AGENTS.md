# Code Style Guide

Main functions should read as a sequence of well-named steps; extract the "how" into helpers.
Orchestration should fit on 1.5 screen heights; extract the rest.
Functions should fit in your head: <8 lines ideal, 8-15 acceptable, 15+ extract or justify.
Check invariants with guards at the top of functions; return or throw if they fail.
Push side effects to the edges: fetch, transform (pure), emit. Don't interleave I/O with logic.

## Comments

- Pre-existing comments: Leave pre-existing comments (from before this PR) intact when editing code

- New comments: Do NOT introduce new comments unless it's a truly exceptional case / noteworthy. You may override this rule if the user requests it explicitly.


## TypeScript / JavaScript Code Style Guide

- Always use `const myFunc = () => ...` in typescript.
- Use `export const` and only use `export default` if it's needed by a library or framework
- Always define functions at the root scope, do not nest function definitions in functions unless really you need to
- Always use TypeScript `type` in favor of `interface` unless you must use interface (or it follows conventions in the code)
- Favor `??` over `||` where it makes sense.
- Never use nullish coalescing assignment (`??=`).
- Favor `Boolean(blah)` over `!!blah`
- Do not use: `while`, `switch`, `continue`, `break`, `in` keywords except if there is good reason to do so
- New comments: Always single line // comments
- Existing comments: Keep comment style that was there before
- Prefer immutable, functional code where possible. (If it's neater to mutate, this is fine)

If your solution or decisions came from a url online, cite your sources and include links.

<example>
user: How do I send JSON data with curl?
assistant: According to the offical curl docs https://curl.se/docs/manual.html, you can send JSON data using the `-d` flag with a Content-Type header.

https://curl.se/docs/manual.html states:
````
With -d, @file, curl will send the data using the content-type application/x-www-form-urlencoded... If you start the data with the letter @, the rest should be a file name to read the data from, or - if you want curl to read the data from stdin.

```bash
curl -X POST https://api.example.com/data \
  -H "Content-Type: application/json" \
  -d '{"name": "example", "value": 123}'
```
````
</example>
I work on Mac or NixOS and the filesystem is case sensitive

To run software without installing it, prefer `nix shell nixpkgs#<pkg> -c <cmd>`; fall back to `mise` for specific tool versions.

Only do git commits when I explicitly ask.

Prefer not to use npx or bunx for anything where package.json has it. Rely on pnpm exec


You can `gh repo clone` helpful repos to `~/code/reference-repos/` and then explore them to figure out how things work.
There is a gitignored `overlay/` folder in all repos:

`overlay/branch` use this by default for your temporary work and experimentation. When I say `overlay` assume this is what I mean.
`overlay/branches` other branches temporary work and experimentation.

Prefer: sketch shape → confirm → implement. Get agreement on structure / APIs / "intefaces" / code seams before details.
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



When referencing files use a format like this from the project dir: ./folder/file.txt or ./folder/file.txt:5 or ./folder/file.txt:4-7
Manual testing means running commands to test something like a human would. But by default, unless asked otherwise, you will do it
## SSH reverse hosts

Detect SSH context with `source ~/Scripts/lib/ssh && is_ssh_session`. Probe reverse tunnel:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=2 -p ${TUNNEL_PORT:-1999} localhost hostname
```

If it works, SSH back with `ssh -p ${TUNNEL_PORT:-1999} localhost`; one-offs: `tunnel-exec <command>`.

```bash
# remote -> originating machine
scp -P ${TUNNEL_PORT:-1999} ./file localhost:~/Downloads/
scp -P ${TUNNEL_PORT:-1999} ./screenshot.png localhost:~/Screenshots/

# originating machine -> remote
scp -P ${TUNNEL_PORT:-1999} localhost:~/Downloads/file ./
scp -P ${TUNNEL_PORT:-1999} localhost:~/Screenshots/screenshot.png ./
```
## Opening links vs browser automation

When the user asks to open/show/launch a URL or link on their machine, use:

```bash
open '<url>'
```

Do not use the browser skill for plain link opening.

Use the browser skill only when the assistant needs to inspect, automate, or interact with the page: click, fill, login, scrape, extract data, test UI, take screenshots, or report what is visible.

If ambiguous, ask: “Should I just open it for you, or should I inspect/interact with it?”

## Parrot output

If I mention “parrot”, it means I'm going to take your response -> edit it -> send it back to you. Be sure to optimize message structure so that it's in a format where it just includes the descisions / requiremens / main points so I can modify it easily.

Default to terse, high-signal responses.

Start with the answer. No preamble.
Use at most 4 short bullets or 2 short paragraphs unless the user asks for more.
Do not restate the question, recap obvious context, or add filler, hedging, or motivational language.
Include only what is needed to act now: the decision, key rationale, commands, paths, risks, and next step.

Expand only when the user explicitly asks or when brevity would risk correctness or safety.
If you must exceed these limits for correctness, say so in one short sentence and continue briefly.

