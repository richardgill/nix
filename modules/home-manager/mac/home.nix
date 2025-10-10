{ vars, ... }:

{
  imports = [
    ../shared/headless/home.nix
  ];

  home = {
    homeDirectory = "/Users/${vars.userName}";
    sessionVariables = {
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
    };
  };
}
