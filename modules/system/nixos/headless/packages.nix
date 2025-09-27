{
  config,
  lib,
  pkgs,
  ...
}:

let
  sharedPackages = import ../../shared/packages.nix { inherit pkgs; };
in
{
  environment.systemPackages = sharedPackages.packages ++ (with pkgs; [
    psmisc
  ]);

  # # Select internationalisation properties.
  # i18n.defaultLocale = "en_GB.UTF-8";
  #
  # i18n.extraLocaleSettings = {
  #   LC_ADDRESS = "en_GB.UTF-8";
  #   LC_IDENTIFICATION = "en_GB.UTF-8";
  #   LC_MEASUREMENT = "en_GB.UTF-8";
  #   LC_MONETARY = "en_GB.UTF-8";
  #   LC_NAME = "en_GB.UTF-8";
  #   LC_NUMERIC = "en_GB.UTF-8";
  #   LC_PAPER = "en_GB.UTF-8";
  #   LC_TELEPHONE = "en_GB.UTF-8";
  #   LC_TIME = "en_GB.UTF-8";
  # };

  # # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "gb";
  #   variant = "";
  # };
  #
  # # Configure console keymap
  # console.keyMap = "uk";
  #
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  #   "1password"
  # ];
  #
  # programs._1password.enable = true;

}
