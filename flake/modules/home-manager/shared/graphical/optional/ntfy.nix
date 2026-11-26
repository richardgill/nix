{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentTopic = config.sops.secrets.ntfy-agent-topic.path;
  githubTopic = config.sops.secrets.ntfy-github-topic.path;

  notifier = pkgs.writeShellApplication {
    name = "show-ntfy-notification";
    runtimeInputs = [
      pkgs.jq
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.terminal-notifier ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.libnotify
      pkgs.xdg-utils
    ];
    text = ''
      app_name="$1"
      title="''${NTFY_TITLE:-$app_name}"
      click="$(jq -r '.click // empty' <<< "$NTFY_RAW")"
      case "$click" in
        http://*|https://*) ;;
        *) click="" ;;
      esac
    ''
    + (
      if pkgs.stdenv.isDarwin then
        ''
          args=(-title "$title" -message "$NTFY_MESSAGE" -group "ntfy-$app_name")
          if [[ -n "$click" ]]; then
            args+=(-open "$click")
          fi
          exec terminal-notifier "''${args[@]}"
        ''
      else
        ''
          args=(--app-name="$app_name" -- "$title" "$NTFY_MESSAGE")
          if [[ -z "$click" ]]; then
            exec notify-send "''${args[@]}"
          fi

          (
            if [[ "$(notify-send --action=default=Open "''${args[@]}")" == "default" ]]; then
              xdg-open "$click" >/dev/null 2>&1
            fi
          ) &
        ''
    );
  };

  subscriber = pkgs.writeShellApplication {
    name = "ntfy-desktop-subscriber";
    runtimeInputs = [ pkgs.ntfy-sh ];
    text = ''
      umask 077
      runtime_root="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}/ntfy-$UID}"
      config_dir="$runtime_root/ntfy"
      mkdir -p "$config_dir"

      agent_topic="$(<${agentTopic})"
      github_topic="$(<${githubTopic})"
      if [[ -z "$agent_topic" || -z "$github_topic" ]]; then
        printf 'An ntfy topic file is empty\n' >&2
        exit 1
      fi

      cat > "$config_dir/client.yml" <<EOF
      default-host: https://ntfy.sh
      subscribe:
        - topic: "$agent_topic"
          command: '${notifier}/bin/show-ntfy-notification Agent'
        - topic: "$github_topic"
          command: '${notifier}/bin/show-ntfy-notification GitHub'
      EOF

      # ntfy logs full subscription URLs on connection failures.
      exec ntfy subscribe --config="$config_dir/client.yml" --from-config >/dev/null 2>&1
    '';
  };
in
lib.mkMerge [
  {
    sops.secrets.ntfy-agent-topic = { };
    sops.secrets.ntfy-github-topic = { };

    xdg.configFile."notify/ntfy.json".text = builtins.toJSON {
      agent = agentTopic;
      github = githubTopic;
    };
  }
  (lib.mkIf pkgs.stdenv.isLinux {
    systemd.user.services.ntfy-desktop-subscriber = {
      Unit = {
        Description = "ntfy desktop subscriber";
        PartOf = [ "graphical-session.target" ];
        After = [ "sops-nix.service" ];
      };
      Service = {
        ExecStart = "${subscriber}/bin/ntfy-desktop-subscriber";
        Restart = "always";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  })
  (lib.mkIf pkgs.stdenv.isDarwin {
    launchd.agents.ntfy-desktop-subscriber = {
      enable = true;
      config = {
        ProgramArguments = [ "${subscriber}/bin/ntfy-desktop-subscriber" ];
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Background";
        RunAtLoad = true;
      };
    };
  })
]
