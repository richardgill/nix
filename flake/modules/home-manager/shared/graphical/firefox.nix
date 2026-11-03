{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  templates = import ../headless/templates.nix {
    inherit
      lib
      pkgs
      config
      inputs
      ;
  };
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

  firefoxProxyPacPath =
    if pkgs.stdenv.isDarwin then "${firefoxConfigDir}/proxy.pac" else "${firefoxProfilePath}/proxy.pac";

  resolveDarwinFirefoxProfile = ''
    FIREFOX_PROFILE_PATH=""
    FIREFOX_PROFILE_PATH_INI=""
    FIREFOX_PROFILE_IS_RELATIVE=1

    if [ -r "${firefoxConfigDir}/installs.ini" ]; then
      INSTALL_DEFAULT=$(${pkgs.gawk}/bin/awk -F= '/^Default=/{ print $2; exit }' "${firefoxConfigDir}/installs.ini")
      if [ -n "$INSTALL_DEFAULT" ]; then
        FIREFOX_PROFILE_PATH_INI="$INSTALL_DEFAULT"
        case "$INSTALL_DEFAULT" in
          /*)
            FIREFOX_PROFILE_IS_RELATIVE=0
            FIREFOX_PROFILE_PATH="$INSTALL_DEFAULT"
            ;;
          *) FIREFOX_PROFILE_PATH="${firefoxConfigDir}/$INSTALL_DEFAULT" ;;
        esac
      fi
    fi

    if [ ! -d "$FIREFOX_PROFILE_PATH" ]; then
      set -- "${firefoxConfigDir}"/Profiles/*.default-release
      if [ -d "$1" ]; then
        FIREFOX_PROFILE_PATH="$1"
        FIREFOX_PROFILE_PATH_INI="''${FIREFOX_PROFILE_PATH#"${firefoxConfigDir}/"}"
        FIREFOX_PROFILE_IS_RELATIVE=1
      else
        FIREFOX_PROFILE_PATH=""
        FIREFOX_PROFILE_PATH_INI=""
      fi
    fi
  '';

  writeDarwinProfilesIni = ''
        if [ -n "$FIREFOX_PROFILE_PATH_INI" ]; then
          cat > "${firefoxConfigDir}/profiles.ini" <<EOF
    [Profile0]
    Name=default
    IsRelative=$FIREFOX_PROFILE_IS_RELATIVE
    Path=$FIREFOX_PROFILE_PATH_INI
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
    EOF
        fi
  '';

in
{
  home.activation.copyFirefoxConfig = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      mkdir -p "${firefoxConfigDir}"

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        ${resolveDarwinFirefoxProfile}
        ${writeDarwinProfilesIni}
      ''}
      ${lib.optionalString (!pkgs.stdenv.isDarwin) ''
        FIREFOX_PROFILE_PATH="${firefoxProfilePath}"
        cp -f "${builtTemplates}/firefox/profiles.ini" "${firefoxConfigDir}/profiles.ini"
      ''}

      printf '%s\n' "Firefox: installing PAC file: ${firefoxProxyPacPath}"
      if ! {
        rm -f "${firefoxProxyPacPath}" &&
          cp -f "${builtTemplates}/firefox/proxy.pac" "${firefoxProxyPacPath}"
      }; then
        printf '%s\n' \
          "Firefox: failed to replace PAC file." \
          "  Source: ${builtTemplates}/firefox/proxy.pac" \
          "  Destination: ${firefoxProxyPacPath}" >&2
        exit 1
      fi

      if [ -n "$FIREFOX_PROFILE_PATH" ]; then
        mkdir -p "$FIREFOX_PROFILE_PATH"
        cp -f "${builtTemplates}/firefox/user.js" "$FIREFOX_PROFILE_PATH/user.js"
      fi
    '';
  };
}
