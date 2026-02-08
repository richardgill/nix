{
  lib,
  vars,
  ...
}:
let
  compositor = vars.waylandCompositor or "hyprland";
in
{
  assertions = [
    {
      assertion = builtins.elem compositor [
        "hyprland"
        "niri"
      ];
      message = "vars.waylandCompositor must be either \"hyprland\" or \"niri\".";
    }
  ];

  imports =
    lib.optionals (compositor == "hyprland") [ ./wayland-hyprland.nix ]
    ++ lib.optionals (compositor == "niri") [ ./wayland-niri.nix ];
}
