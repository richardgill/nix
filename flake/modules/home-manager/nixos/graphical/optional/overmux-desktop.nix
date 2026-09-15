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
    exec = "${config.home.homeDirectory}/Scripts/overmux-desktop";
    categories = [ "Development" ];
    terminal = false;
  };
}
