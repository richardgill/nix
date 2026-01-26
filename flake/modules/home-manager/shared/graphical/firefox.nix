{
  config,
  lib,
  pkgs,
  osConfig,
  vars,
  ...
}:
let
  homeDir = config.home.homeDirectory;

  # Import shared templates
  templates = import ../headless/templates.nix { inherit lib pkgs config osConfig vars; };
  inherit (templates) builtTemplates;

  firefoxConfigDir =
    if pkgs.stdenv.isDarwin then
      "${homeDir}/Library/Application Support/Firefox"
    else
      "${homeDir}/.mozilla/firefox";

  firefoxProfilePath =
    if pkgs.stdenv.isDarwin then
      "${firefoxConfigDir}/Profiles/default"
    else
      "${firefoxConfigDir}/default";

  policyFolder =
    if pkgs.stdenv.isDarwin then
      "${homeDir}/Applications/Firefox.app/Contents/Resources/distribution"
    else
      "/etc/firefox/policies";

  policiesJson = ../../dot-files/firefox/policies.json;
in
{
  home.file = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
    "${policyFolder}/policies.json".source = policiesJson;
  };

  home.activation.copyFirefoxConfig = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      mkdir -p "${firefoxConfigDir}"
      cp -f "${builtTemplates}/firefox/profiles.ini" "${firefoxConfigDir}/profiles.ini"
      mkdir -p "${firefoxProfilePath}"
      cp -f "${builtTemplates}/firefox/user.js" "${firefoxProfilePath}/user.js"
      rm -f "${firefoxProfilePath}/proxy.pac"
      cp -f "${builtTemplates}/firefox/proxy.pac" "${firefoxProfilePath}/proxy.pac"
      rm -f "${firefoxProfilePath}/search.json.mozlz4"

      # Get Kagi search token from: https://kagi.com/settings/user_details
      KAGI_TOKEN=$(cat "${osConfig.sops.secrets."kagi-search-token".path}")
      TEMP_JSON=$(mktemp)
      ${pkgs.gnused}/bin/sed "s/KAGI_TOKEN_PLACEHOLDER/$KAGI_TOKEN/g" "${builtTemplates}/firefox/search.json" > "$TEMP_JSON"
      ${pkgs.mozlz4a}/bin/mozlz4a "$TEMP_JSON" "${firefoxProfilePath}/search.json.mozlz4"
      rm -f "$TEMP_JSON"
    '';
  };
}
