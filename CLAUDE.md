# Nix Configuration

This repo contains all machine setup and configuration since this is a NixOS system - system packages, services, dotfiles, and home-manager config are all declared here. Sometimes they are suffixed with a .hbs (use `*.ext*` glob to match both).

Assume this config is the configuration for all machines we discuss, unless I say otherwise.

Use the `.justfile` for common tasks and commands.


Run `just switch` after making changes to directly deploy changes (builds and activates the new configuration). Only skip this if the change is particularly dangerous, but home dir changes are fine 

To edit my dot files in `~/` they are actually symlinked from `flake/modules/home-manager/shared/headless/dot-files.nix` so search there. 

We prefer keeping them as text files on disk with handlebar templating when needed.

When adding new persistence directories/files for impermanence, they need to be added in:
- `flake/modules/system/nixos/headless/impermanence.nix`

If build fails with "Path X already exists", move conflicting files to persistence first:
`sudo mkdir -p /persistent/home/$USER/<folder>; sudo mv /home/$USER/<file> /persistent/home/$USER/<folder>/; sudo chown -R $USER:users /persistent/home/$USER/<folder>`

To debug scripts in `flake/modules/home-manager/dot-files/Scripts/`, run them directly from the repo rather than from `~/Scripts/`.

my aliases are in my zshrc file
