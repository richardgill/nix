{ pkgs, ... }:
let
  utils = import ../../../../../utils { inherit pkgs; };
in
{
  wayland.windowManager.hyprland = {
    extraConfig = builtins.readFile (
      utils.renderMustache "hyprland-config" "${./.}/hyprland.conf.mustache" {
        jq = "${pkgs.jq}/bin/jq";
      }
    );
  };
}
