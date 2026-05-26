_:
let
  logoutCommand = "niri msg action quit";
  # Workaround: bar height in config.jsonc aligns with fractional scaling to avoid 1px gaps.
  baseWaybarConfig = builtins.fromJSON (builtins.readFile ./config.jsonc);
  powerModule = baseWaybarConfig."custom/power";
  powerMenuActions = powerModule."menu-actions" // {
    logout = logoutCommand;
  };
  waybarConfig = baseWaybarConfig // {
    "custom/power" = powerModule // {
      "menu-actions" = powerMenuActions;
    };
  };
in
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = waybarConfig;
    };
    style = builtins.readFile ./style.css;
  };

  home.file = {
    ".config/waybar/power_menu.xml".source = ./power_menu.xml;
  };
}
