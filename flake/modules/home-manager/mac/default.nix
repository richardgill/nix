# macOS-specific home-manager config
# Shared packages: modules/home-manager/shared/
{
  inputs,
  ...
}:
{
  imports = [
    ../shared/headless
    ../shared/headless/secrets.nix
    ../shared/graphical
    ./dot-files.nix
    ./home.nix
  ];
}
