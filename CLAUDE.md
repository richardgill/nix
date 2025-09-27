# Nix Configuration

Use the `.justfile` for common tasks and commands.

Run `just check` after making changes to validate the configuration.

Dot files for are managed in `modules/home-manager/dot-files.nix` - we prefer keeping them as text files on disk with mustache templating when needed.

When adding new persistence directories/files for impermanence, they need to be added in both:
- `modules/nixos/cli/impermanence.nix` (for actual persistence)
- `scripts/find-impermanent-files.sh` (to exclude from impermanent file detection)

If build fails with "Path X already exists", move conflicting files to persistence first:
`sudo mkdir -p /persistent/home/$USER/<folder>; sudo mv /home/$USER/<file> /persistent/home/$USER/<folder>/; sudo chown -R $USER:users /persistent/home/$USER/<folder>`
