{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.nix ];

  home.activation.overmuxActiveDesktopCheckout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e "$HOME/code/overmux/active-desktop" && ! -L "$HOME/code/overmux/active-desktop" ]]; then
      mkdir -p "$HOME/code/overmux"
      ln -s "$HOME/code/overmux/main" "$HOME/code/overmux/active-desktop"
    fi
  '';

  xdg.desktopEntries.overmux-desktop = {
    name = "Overmux Desktop";
    icon = "${config.home.homeDirectory}/code/overmux/active-desktop/apps/desktop/build/icon.png";
    exec = "${config.home.homeDirectory}/Scripts/overmux-desktop %u";
    mimeType = [ "x-scheme-handler/overmux" ];
    categories = [ "Development" ];
    terminal = false;
  };

  xdg.mimeApps.defaultApplications."x-scheme-handler/overmux" = "overmux-desktop.desktop";
}
