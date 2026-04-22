{ config, ... }:
let
  appDir = "${config.home.homeDirectory}/code/nix-private/out-of-store-config/services/ai-cron";
  pnpmPath = "${config.home.homeDirectory}/.local/share/mise/shims/pnpm";
  pathEnv = "${config.home.homeDirectory}/.local/share/mise/shims:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin";
in
{
  systemd.user.services.ai-cron = {
    Unit = {
      Description = "AI cron";
    };
    Service = {
      WorkingDirectory = appDir;
      ExecStart = "${pnpmPath} start";
      Restart = "always";
      RestartSec = "2s";
      StateDirectory = "ai-cron";
      Environment = [
        "PATH=${pathEnv}"
        "TELEGRAM_BOT_TOKEN_FILE=${config.home.sessionVariables.TELEGRAM_BOT_TOKEN_FILE}"
        "TELEGRAM_CHAT_ID=${config.home.sessionVariables.TELEGRAM_CHAT_ID}"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
