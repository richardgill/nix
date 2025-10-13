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
