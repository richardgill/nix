{
  config,
  pkgs,
  osConfig,
  ...
}:
let
  template = import ../../../../utils/template.nix { inherit pkgs; };

  firefoxConfigDir =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/Firefox"
    else
      "${config.home.homeDirectory}/.mozilla/firefox";

  firefoxProfilePath =
    if pkgs.stdenv.isDarwin then
      "${firefoxConfigDir}/Profiles/default"
    else
      "${firefoxConfigDir}/default";

  firefoxProfilePathUrlEncoded =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Library/Application%20Support/Firefox/Profiles/default"
    else
      "${firefoxConfigDir}/default";

  policyFolder =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Applications/Firefox.app/Contents/Resources/distribution"
    else
      "/etc/firefox/policies";

  disclaimer =
    "By modifying this file, I agree that I am doing so "
    + "only within Firefox itself, using official, user-driven search "
    + "engine selection processes, and in a way which does not circumvent "
    + "user consent. I acknowledge that any attempt to change this file "
    + "from outside of Firefox is a malicious act, and will be responded "
    + "to accordingly.";

  salt = "default" + "Kagi" + disclaimer;

  defaultEngineIdHash = pkgs.lib.removeSuffix "\n" (
    builtins.readFile (
      pkgs.runCommand "firefox-search-hash" { } ''
        echo -n "${salt}" | ${pkgs.openssl}/bin/openssl dgst -sha256 -binary | ${pkgs.coreutils}/bin/base64 > "$out"
      ''
    )
  );

  userJs = builtins.readFile (
    template.renderMustache "firefox-user-js" ../../dot-files/firefox/user.js.mustache {
      inherit (config.home) homeDirectory;
      inherit firefoxProfilePathUrlEncoded;
      isLinux = !pkgs.stdenv.isDarwin;
    }
  );

  searchJson = builtins.readFile (
    template.renderMustache "firefox-search-json" ../../dot-files/firefox/search.json.mustache {
      inherit defaultEngineIdHash;
    }
  );

  # This file is not raw .json it's compressed in a mozilla specific way
  searchJsonMozlz4 = pkgs.runCommand "search.json.mozlz4" { } ''
    echo '${searchJson}' | ${pkgs.mozlz4a}/bin/mozlz4a /dev/stdin "$out"
  '';

  policiesJson = ../../dot-files/firefox/policies.json;

  pacFile = ../../dot-files/firefox/proxy.pac;

  profilePath = if pkgs.stdenv.isDarwin then "Profiles/default" else "default";

  profilesIni = builtins.readFile (
    template.renderMustache "firefox-profiles-ini" ../../dot-files/firefox/profiles.ini.mustache {
      inherit profilePath;
    }
  );
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
      echo '${profilesIni}' > "${firefoxConfigDir}/profiles.ini"
      mkdir -p "${firefoxProfilePath}"
      echo '${userJs}' > "${firefoxProfilePath}/user.js"
      rm -f "${firefoxProfilePath}/proxy.pac"
      cp "${pacFile}" "${firefoxProfilePath}/proxy.pac"
      rm -f "${firefoxProfilePath}/search.json.mozlz4"

      # Get Kagi search token from: https://kagi.com/settings/user_details
      KAGI_TOKEN=$(cat "${osConfig.sops.secrets."kagi-search-token".path}")
      TEMP_JSON=$(mktemp)
      echo '${searchJson}' | ${pkgs.gnused}/bin/sed "s/KAGI_TOKEN_PLACEHOLDER/$KAGI_TOKEN/g" > "$TEMP_JSON"
      ${pkgs.mozlz4a}/bin/mozlz4a "$TEMP_JSON" "${firefoxProfilePath}/search.json.mozlz4"
      rm -f "$TEMP_JSON"
    '';
  };
}
