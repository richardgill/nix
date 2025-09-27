When adding / modifying code in my code base do NOT add comments unless it's a truly exceptional case. 
When writing TypeScript / JavaScript:
  - Always use `const myFunc = () => ...` in typescript. 
  - Use `export const` and only use `export default` if it's needed by a library or framework
  - Always define functions at the root scope, do not nest function definitions in functions unless really you need to
When doing `git commit` write messages which are short, do not prefix them, I use a squash commit workflow, so the commit only shows up in the PR. Example: `git commit -m "Made pay button green"`
When creating PRs use the following convention for monorepo projects: [App name|Package name]: What the PR does. Example [Website]: Made pay button green
