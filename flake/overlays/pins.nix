# For each pinned package below, include a comment explaining why it is pinned,
# when it should be removed or revisited, and any relevant upstream/Nixpkgs links.
{ inputs }:
final: prev:
let
  # Pin Firefox below 150 because Firefox 150 has a native Wayland popup/context-menu
  # rendering regression. Remove once Firefox 151+ is available in nixpkgs.
  # https://bugzilla.mozilla.org/show_bug.cgi?id=2026258
  oldFirefoxPkgs = import inputs.nixpkgs-firefox-wayland-context-menu-fix {
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  firefoxWaylandContextMenuFix = prev.symlinkJoin {
    name = "firefox-${oldFirefoxPkgs.firefox.version}";
    paths = [ oldFirefoxPkgs.firefox ];
    nativeBuildInputs = [ prev.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/firefox
      makeWrapper ${prev.lib.getExe oldFirefoxPkgs.firefox} $out/bin/firefox \
        --add-flags --allow-downgrade
    '';
  };
in
{
  firefox = firefoxWaylandContextMenuFix;
}
