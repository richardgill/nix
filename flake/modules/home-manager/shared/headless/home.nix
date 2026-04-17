{
  vars,
  pkgs,
  config,
  osConfig,
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
      TELEGRAM_BOT_TOKEN_FILE = osConfig.sops.secrets."telegram-bot-token".path;
      TELEGRAM_CHAT_ID = "7743550827";
    };

    sessionPath = [
      "${androidHome}/platform-tools"
      "${androidHome}/emulator"
    ];
  };
}
