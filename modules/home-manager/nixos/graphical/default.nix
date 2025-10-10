{
  ...
}:
{
  imports = [
    ../headless
    ../../shared/graphical
    ./hyprland
    ./mimetypes.nix
    ./packages.nix
    ./rofi/rofi.nix
    ./satty.nix
    ./swayosd.nix
    ./walker/walker.nix
    ./waybar/waybar.nix
    ./webapps.nix
  ];

  # Auto-restart changed services on switch (default: "suggest" only prints hints)
  systemd.user.startServices = "sd-switch";
}
