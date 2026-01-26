{ vars, ... }:

{
  imports = [
    ../../shared/headless/home.nix
  ];

  home = {
    homeDirectory = "/home/${vars.userName}";
  };
}
