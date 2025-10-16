{ ... }:
{
  imports = [
    ../headless
    ./1password.nix
    ./devices.nix
    ./firefox.nix
    ./fonts.nix
    ./gnome-desktop-manager.nix
    ./hyprland.nix
    ./keyboard.nix
    ./packages.nix
    ./stylix.nix
    ./swayosd.nix
    ./wayland.nix
  ];
}
