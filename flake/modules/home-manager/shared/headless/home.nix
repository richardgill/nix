{
  vars,
  pkgs,
  config,
  ...
}:
let
  androidHome =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Library/Android/sdk"
    else
      "${config.home.homeDirectory}/Android/Sdk";
in
{
  home = {
    username = vars.userName;
    stateVersion = "23.11";

    sessionVariables = {
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      JAVA_HOME = pkgs.jdk17.home;
      ANDROID_HOME = androidHome;
      ANDROID_SDK_ROOT = androidHome;
    };

    sessionPath = [
      "${androidHome}/platform-tools"
      "${androidHome}/emulator"
    ];
  };
}
