{
  pkgs,
  vars,
  ...
}: {
  imports = [
    ../headless
    ./fonts.nix
    ./gnome-desktop-manager.nix
    ./hyprland.nix
    ./packages.nix
    ./stylix.nix
    ./swayosd.nix
    ./wayland.nix
    ./xremap.nix
  ];

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };

  programs._1password.enable = true;
  programs._1password-gui.enable = true;
}
