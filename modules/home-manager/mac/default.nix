# macOS-specific home-manager config
# Shared packages: modules/home-manager/shared/
{
  inputs,
  ...
}:
{
  imports = [
    ../shared/headless
    ../shared/graphical
    ./dot-files.nix
    ./home.nix
  ];
}
