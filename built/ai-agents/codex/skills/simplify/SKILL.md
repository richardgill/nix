---
name: simplify
description: Review implementation for simplification opportunities
---

Run `~/Scripts/git-pr-diff`.

Are there any ways you can simplify the implementation? I want the implementation to be as clean, readable and understandable as possible. Try to avoid:

- Unnecessary indirection that makes things harder to understand
- Backwards compatability that is unnecessary or makes things more complex

If there are functional changes that simplify the implementatino, you can ask me if we can simplify that too.
