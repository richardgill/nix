---
name: gmail
description: Gmail via gws.
---

# Gmail via gws

Use `gws` for Gmail operations.

When you need the official generated skill docs, create a temp directory under `/tmp/`, run `gws generate-skills` there, concatenate the generated Gmail skill docs into one file, then read that file:

```bash
tmpdir="$(mktemp -d /tmp/gws-gmail.XXXXXX)"
combined="$tmpdir/gws-gmail.md"
(
  cd "$tmpdir"
  gws generate-skills
  shopt -s nullglob
  : > "$combined"
  for file in skills/gws-gmail*/SKILL.md; do
    printf '\n\n%s\n\n' "--- $file ---" >> "$combined"
    cat "$file" >> "$combined"
  done
)
```

You only need to read this:
- `$tmpdir/gws-gmail.md`
