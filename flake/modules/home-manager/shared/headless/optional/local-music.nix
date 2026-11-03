{
  lib,
  pkgs,
  config,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  cmusFiles = ../../../dot-files/cmus;
in
{
  home.packages = [ pkgs.cmus ];

  # Cmus files (from built templates)
  # Now copied directly from static sources.
  home.activation.copyCmusFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${homeDir}/.config/cmus
    cp -f ${cmusFiles}/start ${homeDir}/.config/cmus/start
    chmod +x ${homeDir}/.config/cmus/start
    cp -f ${cmusFiles}/rc ${homeDir}/.config/cmus/rc
    cp -f ${cmusFiles}/tokyo-night.theme ${homeDir}/.config/cmus/tokyo-night.theme
  '';
}
