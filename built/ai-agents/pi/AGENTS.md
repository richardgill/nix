# Code Style Guide

Main functions should read as a sequence of well-named steps; extract the "how" into helpers.
Orchestration should fit on 1.5 screen heights; extract the rest.
Functions should fit in your head: <8 lines ideal, 8-15 acceptable, 15+ extract or justify.
Check invariants with guards at the top of functions; return or throw if they fail.
Push side effects to the edges: fetch, transform (pure), emit. Don't interleave I/O with logic.

## Comments

- Pre-existing comments: Leave pre-existing comments (from before this PR) intact when editing code

- New comments: Do NOT introduce new comments unless it's a truly exceptional case / noteworthy

## TypeScript / JavaScript Code Style Guide

- Always use `const myFunc = () => ...` in typescript.
- Use `export const` and only use `export default` if it's needed by a library or framework
- Always define functions at the root scope, do not nest function definitions in functions unless really you need to
- Always use TypeScript `type` in favor of `interface` unless you must use interface (or it follows conventions in the code)
- Favor `??` over `||` where it makes sense.
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

Only do git commits when I explicitly ask.

Prefer not to use npx or bunx for anything where package.json has it. Rely on pnpm exec

There is a gitignored `scratch/` folder in all repos - you can use it for temporary work and experimentation.

You can `gh repo clone` helpful repos to `~/code/reference-repos/` and then explore them to figure out how things work.

When referencing files use a format like this from the project dir: ./folder/file.txt or ./folder/file.txt:4-7
