---
name: google-calendar
description: Google Calendar via gws.
---

# Google Calendar via gws

Use `gws` for Google Calendar operations.

When you need the official generated skill docs, create a temp directory under `/tmp/`, run `gws generate-skills` there, concatenate the generated Calendar skill docs into one file, then read that file:

```bash
tmpdir="$(mktemp -d /tmp/gws-calendar.XXXXXX)"
combined="$tmpdir/gws-calendar.md"
(
  cd "$tmpdir"
  gws generate-skills
  shopt -s nullglob
  : > "$combined"
  for file in skills/gws-calendar*/SKILL.md; do
    printf '\n\n%s\n\n' "--- $file ---" >> "$combined"
    cat "$file" >> "$combined"
  done
)
```

You only need to read this:
- `$tmpdir/gws-calendar.md`
