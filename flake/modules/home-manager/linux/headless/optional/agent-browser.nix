{ lib, pkgs, ... }:
{
  home.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
}
