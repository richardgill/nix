{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
# Web app configuration using chromium in app mode
# To login to services, launch chromium directly and sign in there first
#
# Zoom uses a dedicated chromium profile at ~/.config/chromium-zoom with
# "Continue where I left off" pre-enabled. This converts Zoom's session
# cookies into persistent ones for that profile only, so the login survives
# closing the Zoom app window. Sign into Zoom once after first launch.
let
  zoomUserDataDir = "${config.home.homeDirectory}/.config/chromium-zoom";

  zoomPrefs = builtins.toJSON {
    session.restore_on_startup = 1;
    profile.exit_type = "Normal";
  };

  launchWebappScript = pkgs.writeShellScriptBin "omarchy-launch-webapp" (builtins.readFile ./webapps/omarchy-launch-webapp.sh);

  zoomHandlerScript = pkgs.writeShellScriptBin "omarchy-webapp-handler-zoom" ''
    export ZOOM_USER_DATA_DIR="${zoomUserDataDir}"
    ${builtins.readFile ./webapps/omarchy-webapp-handler-zoom.sh}
  '';
in
{
  home.packages = [
    launchWebappScript
    zoomHandlerScript
  ];

  home.activation.seedZoomChromiumProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${zoomUserDataDir}/Default"
    if [ ! -f "${zoomUserDataDir}/Default/Preferences" ]; then
      echo '${zoomPrefs}' > "${zoomUserDataDir}/Default/Preferences"
    fi
  '';

  xdg.desktopEntries.zoom-web = {
    name = "Zoom";
    exec = "${zoomHandlerScript}/bin/omarchy-webapp-handler-zoom %U";
    icon = ./webapps/icons/zoom.svg;
    comment = "Zoom Web Client";
    categories = [
      "Network"
      "VideoConference"
    ];
    terminal = false;
    mimeType = [
      "x-scheme-handler/zoom"
      "x-scheme-handler/zoomus"
      "x-scheme-handler/zoommtg"
    ];
    settings = {
      StartupNotify = "true";
    };
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/zoom" = "zoom-web.desktop";
    "x-scheme-handler/zoomus" = "zoom-web.desktop";
    "x-scheme-handler/zoommtg" = "zoom-web.desktop";
  };
}
