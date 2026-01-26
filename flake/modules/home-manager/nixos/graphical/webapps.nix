{
  config,
  lib,
  pkgs,
  ...
}:
# Web app configuration using chromium in app mode
# To login to services, launch chromium directly and sign in there first
#
# Note: Zoom web keeps logging out when browser closes due to session cookies.
# To fix: Enable "Continue where I left off" in chrome://settings/onStartup
# This will persist session cookies across browser restarts (affects all sites).
let
  launchWebappScript = pkgs.writeShellScriptBin "omarchy-launch-webapp" (
    builtins.readFile ./webapps/omarchy-launch-webapp.sh
  );

  zoomHandlerScript = pkgs.writeShellScriptBin "omarchy-webapp-handler-zoom" (
    builtins.readFile ./webapps/omarchy-webapp-handler-zoom.sh
  );
in
{
  home.packages = [
    launchWebappScript
    zoomHandlerScript
  ];

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
