# Nix Configuration

This repo contains all machine setup and configuration since this is a NixOS system - system packages, services, dotfiles, and home-manager config are all declared here.

Use the `.justfile` for common tasks and commands.

Run `just check` after making changes to validate the configuration.

Dot files in `~/` are symlinked from `modules/home-manager/dot-files.nix` - we prefer keeping them as text files on disk with mustache templating when needed.

When adding new persistence directories/files for impermanence, they need to be added in:
- `modules/nixos/cli/impermanence.nix`

If build fails with "Path X already exists", move conflicting files to persistence first:
`sudo mkdir -p /persistent/home/$USER/<folder>; sudo mv /home/$USER/<file> /persistent/home/$USER/<folder>/; sudo chown -R $USER:users /persistent/home/$USER/<folder>`
