{ ... }:
{
  imports = [
    ../headless
    ./1password.nix
    ./firefox.nix
    ./fonts.nix
    ./gnome-desktop-manager.nix
    ./hyprland.nix
    ./packages.nix
    ./stylix.nix
    ./swayosd.nix
    ./wayland.nix
    ./xremap.nix
  ];
}
