{
  inputs,
  ...
}:
{
  imports = [
    # Make sure nix installed apps are available in spotlight https://github.com/hraban/mac-app-util
    inputs.mac-app-util.homeManagerModules.default
    ../shared/headless
    ../shared/graphical
    ./dot-files.nix
    ./home.nix
  ];
}
