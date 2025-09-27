{ lib, pkgs, vars, osConfig, ... }: {
  imports = [
    ../../shared/headless
  ];

  home = {
    username = vars.userName;
    homeDirectory = "/home/${vars.userName}";
    stateVersion = "23.11";
  };
}