# Nix Configuration

This repository declaratively manages machine setup and configuration, including system packages, services, dotfiles, and Home Manager configuration. Assume it configures every machine we discuss unless I say otherwise.

Dotfile templates may use the `.hbs` suffix. Use `*.ext*` globs when searching for both templated and non-templated versions.

## Important locations

- `./.justfile` - task definitions.
- `./flake/` - declarative system configuration.
- `./out-of-store-config/` - application configuration kept outside the Nix store.
- `./flake/modules/home-manager/shared/headless/dot-files.nix` - home-directory dotfile declarations.
- `./flake/modules/home-manager/dot-files/` - managed dotfile sources.
- `./flake/modules/home-manager/dot-files/zsh/zshrc.hbs` - shell aliases and zsh configuration.
- `./flake/modules/home-manager/dot-files/Scripts/` - custom scripts.
- `./flake/modules/home-manager/dot-files/ai-agents/shared/partials/AGENTS.md.hbs` - shared instructions and defaults rendered into AI-agent configuration.
- `./flake/modules/system/nixos/headless/impermanence.nix` - persistence declarations.
- `./flake/overlays/pins.nix` - package pin declarations.

## Workflow

- Use the `.justfile` for common tasks and commands.
- When I say "switch", run `just switch` for me.
- After changing `./flake/`, run `just switch` to build and activate the configuration. Only skip this for particularly dangerous changes; home-directory changes are safe to apply.
- Changes under `./out-of-store-config/` are picked up after relaunching the affected program and do not require `just switch`.
- Edit the repository sources for dotfiles rather than their symlinks in `~/`.
- Prefer keeping dotfiles as text files on disk, using Handlebars templates when needed.
- Put temporary package pins in `./flake/overlays/pins.nix`. Above each pin, explain why it exists, when to remove or revisit it, and include relevant upstream or Nixpkgs links.
- Run `overmux ai context` for documentation about Overmux.


- Add new impermanence persistence directories and files to `./flake/modules/system/nixos/headless/impermanence.nix`.
- If a build fails with `Path X already exists`, move the conflicting files to persistence first:

```sh
sudo mkdir -p /persistent/home/$USER/<folder>
sudo mv /home/$USER/<file> /persistent/home/$USER/<folder>/
sudo chown -R $USER:users /persistent/home/$USER/<folder>
```
