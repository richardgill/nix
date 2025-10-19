{
  config,
  inputs,
  pkgs,
  vars,
  ...
}:
let
  sharedPackages = import ../shared/headless/packages.nix { inherit pkgs; };
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
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    # Installing desktop applications via nix puts them in a symlinked folder "~/Applications/Nix Apps" this stops spotlight and many other things (permissions?) from working. So we install them via brew instead
    casks = [
      "1password"
      "alacritty"
      "beeper"
      "cursor"
      "discord"
      "docker"
      "firefox"
      "flameshot"
      "ghostty"
      "google-chrome"
      "hammerspoon"
      "karabiner-elements"
      "rectangle"
      "slack"
      "sol"
      "spotify"
      "stats"
      "tailscale-app"
      "todoist-app"
      "visual-studio-code"
      "zoom"
    ];
    masApps = {
    };
  };

  system.activationScripts.extraActivation.text = ''
    if ! xcode-select -p &> /dev/null; then
      echo "⚠️  Xcode Command Line Tools not found"
      echo "Please install them using: xcode-select --install"
      exit 1
    fi
    softwareupdate --install-rosetta --agree-to-license
  '';
}
