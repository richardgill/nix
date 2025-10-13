{
  config,
  pkgs,
  ...
}:
let
  template = import ../../../../utils/template.nix { inherit pkgs; };

  firefoxProfilePath =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/Firefox/Profiles/default"
    else
      "${config.home.homeDirectory}/.mozilla/firefox/default";

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

  defaultEngineIdHash = pkgs.lib.removeSuffix "\n" (builtins.readFile (
    pkgs.runCommand "firefox-search-hash" { } ''
      echo -n "${salt}" | ${pkgs.openssl}/bin/openssl dgst -sha256 -binary | ${pkgs.coreutils}/bin/base64 > "$out"
    ''
  ));

  userJs = builtins.readFile (
    template.renderMustache "firefox-user-js" ../../dot-files/firefox/user.js.mustache {
      homeDirectory = config.home.homeDirectory;
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
      mkdir -p "${config.home.homeDirectory}/.mozilla/firefox"
      echo '${profilesIni}' > "${config.home.homeDirectory}/.mozilla/firefox/profiles.ini"
      mkdir -p "${firefoxProfilePath}"
      echo '${userJs}' > "${firefoxProfilePath}/user.js"
      rm -f "${firefoxProfilePath}/search.json.mozlz4"
      cp -f "${searchJsonMozlz4}" "${firefoxProfilePath}/search.json.mozlz4"
    '';
  };
}
