---
description: Post code review comments to GitHub PR
---

Post prepared review comments as a **pending** (draft) GitHub review. Do NOT submit/approve - leave as pending for user to finalize.

## Todo List

1. Find PR for current branch: `gh pr list --head <current_branch> --json number,headRefOid`
2. If no PR, stop and tell user
3. Get PR diff: `gh api repos/{owner}/{repo}/pulls/{pr} -H "Accept: application/vnd.github.v3.diff"`
4. For each issue, calculate its **position** in the diff (see Position Calculation below)
5. Categorize each issue into one of three types:
   - a) **Not in diff** → add to review `body` with GitHub link (see Generating File Links below)
   - b) **In diff + isolated one-line change** → use suggestion block (see Suggestion Syntax below)
   - c) **In diff + multi-line/contextual** → normal line comment
6. For In diff + isolated one-line change suggestion blocks:
   - The line is a single added/modified line (starts with `+`)
   - The suggestion contains the exact replacement code for that line
   - Make the changes to the code locally here
   - Run pnpm run local-ci to check everything is ok, if this fails, make it a In diff 5 c.
7. Write JSON to `scratch/review-<pr>-<current_branch>.json`
8. Post review: `gh api repos/{owner}/{repo}/pulls/{pr}/reviews --input scratch/review-<pr>-<current_branch>.json`
9. Verify comments attached: `gh api repos/{owner}/{repo}/pulls/{pr}/reviews/{id}/comments` - check `position` field is populated
10. Show PR link to user

## Position Calculation

**Use `position`, NOT `line`** - the `line` parameter doesn't work reliably.

Position = number of lines from first `@@` header in that file's diff:
- The `@@` header itself is NOT counted
- Position 1 = first line after `@@`
- Continue counting through ALL lines including subsequent `@@` headers

Example:
@@ -1,5 +1,5 @@        <- not counted
+import { Button }      <- position 1
 import Link            <- position 2
-import { Old }         <- position 3
@@ -93,7 +93,7 @@       <- position 4 (headers count after first!)
   asChild              <- position 5
-  variant="old"        <- position 6
+  variant="new"        <- position 7  <-- comment here = position 7

## Post review JSON

```json
{
  "commit_id": "abc123...",
  "body": "Claude Code Generated:\n\n3 issues found.\n\n**Not in diff:**\n- `utils/format.ts:42` - unused import",
  "comments": [
    {
      "path": "src/components/button.tsx",
      "position": 7,
      "body": "Missing null check:\n\n```suggestion\n  if (!value) return null;\n```"
    },
    {
      "path": "src/api/client.ts",
      "position": 15,
      "body": "Consider using `const` here since this is never reassigned."
    }
  ]
}
```

- Body format: `Claude Code Generated:` → `{count} issues found.` → `**Not in diff:**` with file:line refs

## Suggestion Syntax

GitHub "suggested changes" let reviewees apply fixes with one click. Include a fenced code block with `suggestion` as the language:

````markdown
Consider using `const`:

```suggestion
  const value = true;
```
````

- Only works on single `+` lines in the diff
- The suggestion replaces the entire line - include correct indentation
- GitHub renders an "Apply suggestion" button for the PR author

## Generating File Links

Use `gh browse` with `-n` and `--commit` to generate GitHub URLs pinned to the PR's commit:

```bash
gh browse path/to/file.ts:42 -n --commit=$COMMIT_SHA
# outputs: https://github.com/owner/repo/blob/<sha>/path/to/file.ts#L42
```

Use the `headRefOid` from step 1 as `$COMMIT_SHA`.

## Notes

- **CRITICAL:** Omit `event` field entirely to create pending (draft) review
- Use `position`, not `line` for reliable line attachment
- Position must point to a line that exists in the diff
- Suggestion blocks only work on single `+` lines in the diff
