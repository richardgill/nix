I work on Mac or NixOS and the filesystem is case sensitive

To run software without installing it, prefer `nix shell nixpkgs#<pkg> -c <cmd>`; fall back to `mise` for specific tool versions.

Only do git commits when I explicitly ask.

Prefer not to use npx or bunx for anything where package.json has it. Rely on pnpm exec


You can `gh repo clone` helpful repos to `~/code/reference-repos/` and then explore them to figure out how things work.
