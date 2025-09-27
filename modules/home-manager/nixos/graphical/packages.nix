{
  config,
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:

let
  unstable = import nixpkgs-unstable { system = pkgs.system; config.allowUnfree = true; };
in

{
  home.packages =
    with pkgs;
    [
      nautilus
      evince
      imv
      sushi
      satty
      wl-clipboard
      swayosd
      walker
      slurp
      wl-clip-persist
      cliphist
      wf-recorder
      glib
      wayland
      unstable.wiremix
    ]
    ++ lib.optionals (!pkgs.stdenv.isAarch64) [
      ghostty
    ];
}
