{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../headless
    ../../shared/graphical
    ./hyprland
    ./waybar/waybar.nix
    ./walker/walker.nix
    ./rofi/rofi.nix
    ./packages.nix
    ./mimetypes.nix
    ./satty.nix
    ./swayosd.nix
  ];

  # Auto-restart changed services on switch (default: "suggest" only prints hints)
  systemd.user.startServices = "sd-switch";
}
