{
  lib,
  vars,
  ...
}:
{
  imports =
    [
      ../headless
      ../../shared/graphical
      ./file-roller.nix
      ./mako.nix
      ./mimetypes.nix
      ./packages.nix
      ./rofi/rofi.nix
      ./satty.nix
      ./swayosd.nix
      # ./walker/walker.nix
      ./waybar/waybar.nix
      ./webapps.nix
    ]
    ++ lib.optionals ((vars.waylandCompositor or "hyprland") == "hyprland") [
      ./hyprland
    ]
    ++ lib.optionals ((vars.waylandCompositor or "hyprland") == "niri") [
      ./niri
    ];

  # Auto-restart changed services on switch (default: "suggest" only prints hints)
  systemd.user.startServices = "sd-switch";
}
