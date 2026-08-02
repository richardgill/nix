_: {
  imports = [
    ../headless
    ../../shared/graphical
    ./file-roller.nix
    ./mako.nix
    ./mimetypes.nix
    ./packages.nix
    ./satty.nix
    ./swayosd.nix
    ./walker/walker.nix
    ./waybar/waybar.nix
    ./webapps.nix
    ./niri
  ];

  # Auto-restart changed services on switch (default: "suggest" only prints hints)
  systemd.user.startServices = "sd-switch";
}
