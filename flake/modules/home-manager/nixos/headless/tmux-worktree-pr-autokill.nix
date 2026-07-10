{ config, pkgs, ... }:
let
  pathEnv = "${config.home.homeDirectory}/.local/share/mise/shims:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin";
in
{
  systemd.user.services.tmux-worktree-pr-autokill = {
    Unit.Description = "Kill tmux worktree sessions for merged PRs";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -lc '${config.home.homeDirectory}/Scripts/worktree-pr-autokill --quiet'";
      Environment = [ "PATH=${pathEnv}" ];
    };
  };

  systemd.user.timers.tmux-worktree-pr-autokill = {
    Unit.Description = "Check for merged PR worktree tmux sessions";
    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "30s";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
