{
  config,
  inputs,
  pkgs,
  vars,
  ...
}:
let
  sharedPackages = import ../shared/packages.nix { inherit pkgs; };
in
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  environment.systemPackages = sharedPackages.packages;

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = vars.userName;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-core" = inputs.homebrew-core;
    };
  };

  homebrew = {
    enable = true;
    global = {
      autoUpdate = true;
    };
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };
    brews = [
      "mise"
      # "trash"
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "alfred"
      "cursor"
      "ghostty"
      "hammerspoon"
      "karabiner-elements"
      "monarch"
      "rectangle"
      "signal"
      # "1password-cli"
      # "1password"
      # "alacritty"
      # "discord"
      # "firefox"
      # "screen-studio"
      # "spotify"
      # "the-unarchiver"
      # "visual-studio-code"
      # "vlc"
      # "whatsapp"
    ];
    masApps = {
    };
  };

  system.activationScripts.extraActivation.text = ''
    softwareupdate --install-rosetta --agree-to-license
  '';
}
