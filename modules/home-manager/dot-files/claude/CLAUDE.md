When adding / modifying code in my code base do NOT add comments unless it's a truly exceptional case, never remove comments that are already there.
When writing TypeScript / JavaScript:
  - Always use `const myFunc = () => ...` in typescript.
  - Use `export const` and only use `export default` if it's needed by a library or framework
  - Always define functions at the root scope, do not nest function definitions in functions unless really you need to

Always use TypeScript `type` in favor of `interface` unless you must use interface (or it follows conventions in the code)

Favor `??` over `||` where it makes sense.

Favor `Boolean(blah)` over `!!blah`

I work on Mac or NixOS and the filesystem is case sensitive

Only do git commits when I explicitly ask.

Prefer not to use npx or bunx for anything where package.json has it. Rely on pnpm exec

Never use: `while`, `switch`, `continue`, `break` keywords except if there is good reason to do so

If your solution came from a url online, please include cite your sources and include links.

There is a gitignored `scratch/` folder in all repos - you can use it for temporary work and experimentation.
