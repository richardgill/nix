{
  vars,
  osConfig,
  ...
}:
{
  home = {
    username = vars.userName;
    stateVersion = "23.11";

    sessionVariables = {
      COLORTERM = "truecolor";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      TELEGRAM_BOT_TOKEN_FILE = osConfig.sops.secrets."telegram-bot-token".path;
      TELEGRAM_CHAT_ID = "7743550827";
    };

  };
}
