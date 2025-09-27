{ lib, pkgs, vars, osConfig, inputs, ... }: {
  imports = [
    ../shared/headless
    ../shared/graphical
    ./dot-files.nix
    # Make sure nix installed apps are available in spotlight https://github.com/hraban/mac-app-util 
    inputs.mac-app-util.homeManagerModules.default
  ];

  home = {
    username = vars.userName;
    homeDirectory = "/Users/${vars.userName}";
    stateVersion = "23.11";
    sessionVariables = {
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
    };
  };
}
