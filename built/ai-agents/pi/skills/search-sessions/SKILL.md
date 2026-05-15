---
name: search-sessions
description: |
  Search saved pi chats, pi conversations, pi sessions, Claude Code chats, Claude Code conversations, and Claude Code sessions.
  Triggers: "search pi chats", "search pi conversations", "search pi sessions", "find in pi chats", "search Claude Code sessions", "search Claude Code conversations", "search Claude chats", "find in Claude history", "where did we discuss", "search agent conversations".
---

# Search Sessions

Use this skill when asked to search previous agent chats, conversations, session history, or saved JSONL transcripts for pi or Claude Code.

## Scope

- pi sessions: `~/.pi/agent/sessions`
- Claude Code sessions: `~/.claude/projects`
- Include Claude Code subagent sessions.
- If the user names pi or Claude Code, search only that store.
- If the user asks for this folder, current folder, current project, or this repo, derive the session directory from `$PWD` and search only that directory.
- If the user asks for both/all or does not specify, search pi first, then Claude Code, and report the results in separate groups.

## Pi current-folder search command

Replace `SEARCH TERMS` with the user's query.

```bash
q='SEARCH TERMS'
session_key=$(printf '%s' "$PWD" | sed 's#^/##; s#/#-#g')
rg -0 -l --no-messages --glob '*.jsonl' -i -F "$q" "$HOME/.pi/agent/sessions/--$session_key--" \
  | xargs -0 -r jq -r --arg q "$q" '
    def text:
      if type == "string" then .
      elif type == "array" then map(if type == "string" then . elif .type == "text" then .text else empty end) | join("\n")
      else empty end;
    . as $e
    | ($e.message? // $e) as $m
    | ($m.role? // empty) as $role
    | select($role == "user" or $role == "assistant")
    | (($m.content? // "") | text) as $text
    | select($text | ascii_downcase | contains($q | ascii_downcase))
    | "--- " + input_filename + " " + ($e.timestamp // "") + " " + $role + "\n" + $text + "\n"
  '
```

## Claude Code current-folder search command

Replace `SEARCH TERMS` with the user's query.

```bash
q='SEARCH TERMS'
session_key=$(printf '%s' "$PWD" | sed 's#^/##; s#/#-#g')
rg -0 -l --no-messages --glob '*.jsonl' -i -F "$q" "$HOME/.claude/projects/-$session_key" \
  | xargs -0 -r jq -r --arg q "$q" '
    def text:
      if type == "string" then .
      elif type == "array" then map(if type == "string" then . elif .type == "text" then .text else empty end) | join("\n")
      else empty end;
    . as $e
    | ($e.message? // $e) as $m
    | ($m.role? // empty) as $role
    | select($role == "user" or $role == "assistant")
    | (($m.content? // "") | text) as $text
    | select($text | ascii_downcase | contains($q | ascii_downcase))
    | "--- " + input_filename + " " + ($e.timestamp // "") + " " + $role + "\n" + $text + "\n"
  '
```

## Pi all-sessions search command

Replace `SEARCH TERMS` with the user's query.

```bash
q='SEARCH TERMS'
rg -0 -l --no-messages --glob '*.jsonl' -i -F "$q" "$HOME/.pi/agent/sessions" \
  | xargs -0 -r jq -r --arg q "$q" '
    def text:
      if type == "string" then .
      elif type == "array" then map(if type == "string" then . elif .type == "text" then .text else empty end) | join("\n")
      else empty end;
    . as $e
    | ($e.message? // $e) as $m
    | ($m.role? // empty) as $role
    | select($role == "user" or $role == "assistant")
    | (($m.content? // "") | text) as $text
    | select($text | ascii_downcase | contains($q | ascii_downcase))
    | "--- " + input_filename + " " + ($e.timestamp // "") + " " + $role + "\n" + $text + "\n"
  '
```

## Claude Code all-sessions search command

Replace `SEARCH TERMS` with the user's query.

```bash
q='SEARCH TERMS'
rg -0 -l --no-messages --glob '*.jsonl' -i -F "$q" "$HOME/.claude/projects" \
  | xargs -0 -r jq -r --arg q "$q" '
    def text:
      if type == "string" then .
      elif type == "array" then map(if type == "string" then . elif .type == "text" then .text else empty end) | join("\n")
      else empty end;
    . as $e
    | ($e.message? // $e) as $m
    | ($m.role? // empty) as $role
    | select($role == "user" or $role == "assistant")
    | (($m.content? // "") | text) as $text
    | select($text | ascii_downcase | contains($q | ascii_downcase))
    | "--- " + input_filename + " " + ($e.timestamp // "") + " " + $role + "\n" + $text + "\n"
  '
```

## Output

- Group results under `pi` and `Claude Code` when searching both.
- Show the matching file path, timestamp, role, and a short relevant excerpt.
- If there are many matches, show the best few and say how many files matched.
- To resume pi, use `pi --session <path-or-id>`.
- To inspect Claude Code history, open the matched JSONL file path.

$ARGUMENTS
