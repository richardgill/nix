---
allowed-tools: Bash(~/Scripts/git-local-diff:*), Bash(grep:*)
description: Check local changes for secrets or sensitive data before publishing
---

## Added Lines Only

!`~/Scripts/git-local-diff | grep '^+' | grep -v '^+++'`

## Task

Review the stuff I'm adding from the diff and identify any concerning content that should NOT be published to a public GitHub repository:

- API keys, tokens, or secrets
- Passwords or credentials
- Private IP addresses or internal hostnames
- Personal information (emails, phone numbers, addresses)
- Private file paths that reveal system structure
- Any other sensitive data

If you find concerns, list each one with the file and line.
If everything looks safe to publish, respond with: "No sensitive data detected." and no other content

