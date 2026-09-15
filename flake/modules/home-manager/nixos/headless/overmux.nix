{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.gcc
    pkgs.gnumake
    pkgs.jq
    pkgs.nodejs_22
    pkgs.pnpm
    pkgs.python3
  ];

  home.activation.overmuxActiveCheckout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e "$HOME/code/overmux/active-server" && ! -L "$HOME/code/overmux/active-server" ]]; then
      mkdir -p "$HOME/code/overmux"
      ln -s "$HOME/code/overmux/main" "$HOME/code/overmux/active-server"
    fi
  '';

  systemd.user.services.overmux = {
    Unit = {
      Description = "Overmux server from the active checkout";
      ConditionPathIsDirectory = "%h/code/overmux/active-server";
      ConditionPathExists = [
        "%h/code/overmux/active-server/packages/runtime/overmux/dist/bin.js"
        "%h/code/overmux/active-server/packages/runtime/overmux/dist/exports/index.js"
      ];
      StartLimitIntervalSec = 30;
      StartLimitBurst = 5;
    };
    Service = {
      WorkingDirectory = "%h/code/overmux/active-server";
      ExecStartPre = "${config.home.homeDirectory}/Scripts/overmux-config-install";
      ExecStart = "${pkgs.nodejs_22}/bin/node packages/runtime/overmux/dist/bin.js serve";
      Environment = [
        "PATH=/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
      KillMode = "mixed";
      Restart = "always";
      RestartSec = "2s";
      TimeoutStopSec = "5s";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
