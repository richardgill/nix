{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  githubIcon = ./ntfy-icons/github.png;
  agentIcon = ./ntfy-icons/agent.png;
  isDarwin = pkgs.stdenv.isDarwin;
  notifier = pkgs.writeShellApplication {
    name = "show-ntfy-notification";
    runtimeInputs = [
      pkgs.jq
    ]
    ++ lib.optionals isDarwin [ pkgs.terminal-notifier ]
    ++ lib.optionals (!isDarwin) [
      pkgs.libnotify
      pkgs.xdg-utils
    ];
    text =
      if isDarwin then
        ''
          category="''${1:-agent}"
          title="''${NTFY_TITLE:-Agent}"
          click="$(jq -r '.click // empty' <<< "$NTFY_RAW")"

          if [[ "$category" == "github" ]]; then
            icon="${githubIcon}"
          else
            icon="${agentIcon}"
          fi

          args=(-title "$title" -message "$NTFY_MESSAGE" -appIcon "$icon" -contentImage "$icon" -group "ntfy-$category")
          if [[ -n "$click" ]]; then
            args+=(-open "$click")
          fi

          exec terminal-notifier "''${args[@]}"
        ''
      else
        ''
          category="''${1:-agent}"
          title="''${NTFY_TITLE:-Agent}"
          click="$(jq -r '.click // empty' <<< "$NTFY_RAW")"
          urgency="normal"

          if [[ "$category" == "github" ]]; then
            app_name="GitHub"
            icon="${githubIcon}"
          else
            app_name="Agent"
            icon="${agentIcon}"
          fi

          if [[ "$NTFY_PRIORITY" == "5" ]]; then
            urgency="critical"
          elif [[ "$NTFY_PRIORITY" == "1" ]]; then
            urgency="low"
          fi

          notify_args=(--app-name="$app_name" --icon="$icon" --urgency="$urgency" "$title" "$NTFY_MESSAGE")
          if [[ -z "$click" ]]; then
            exec notify-send "''${notify_args[@]}"
          fi

          (
            action="$(notify-send --action=default=Open "''${notify_args[@]}")"
            if [[ "$action" == "default" ]]; then
              xdg-open "$click" >/dev/null 2>&1
            fi
          ) &
        '';
  };
  subscriber = pkgs.writeShellApplication {
    name = "ntfy-desktop-subscriber";
    runtimeInputs = [ pkgs.ntfy-sh ];
    text = ''
      umask 077
      runtime_root="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}/ntfy-$UID}"
      config_dir="$runtime_root/ntfy"
      config_file="$config_dir/client.yml"
      mkdir -p "$config_dir"

      github_topic="$(<${osConfig.sops.secrets."ntfy-github-topic".path})"
      agent_topic="$(<${osConfig.sops.secrets."ntfy-agent-topic".path})"

      cat > "$config_file" <<EOF
      default-host: https://ntfy.sh
      subscribe:
        - topic: $github_topic
          command: '${notifier}/bin/show-ntfy-notification github'
        - topic: $agent_topic
          command: '${notifier}/bin/show-ntfy-notification agent'
      EOF

      exec ntfy subscribe --config="$config_file" --from-config
    '';
  };
in
lib.mkMerge [
  {
    home.packages = [ pkgs.ntfy-sh ];
  }
  (lib.mkIf pkgs.stdenv.isLinux {
    systemd.user.services.ntfy-desktop-subscriber = {
      Unit = {
        Description = "ntfy desktop subscriber";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${subscriber}/bin/ntfy-desktop-subscriber";
        Restart = "always";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "default.target" ];
    };
  })
  (lib.mkIf isDarwin {
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
