{
  lib,
  vars,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  config =
    let
      phase1Systemd = config.boot.initrd.systemd.enable;

      wipeScript = ''
        mkdir /btrfs_tmp

        # Mount the btrfs root to /btrfs_tmp
        mount -t btrfs -o subvol=/ /dev/mapper/cryptroot /btrfs_tmp

        # Delete the root subvolume
        btrfs subvolume list -o /btrfs_tmp/root | cut -f9 -d' ' |
        while read subvolume; do
          echo "deleting /$subvolume subvolume..."
          btrfs subvolume delete "/btrfs_tmp/$subvolume"
        done &&
        echo "deleting /root subvolume..." &&
        btrfs subvolume delete /btrfs_tmp/root

        echo "restoring blank /root subvolume..."
        btrfs subvolume snapshot /btrfs_tmp/root-blank /btrfs_tmp/root

        # Unmount /btrfs_tmp and continue boot process
        umount /btrfs_tmp
      '';
    in
    {
      users.mutableUsers = lib.mkForce false;
      users.users.${vars.userName}.hashedPasswordFile = "/persistent/passwd_${vars.userName}";
      programs.fuse.userAllowOther = true;

      environment.persistence."/persistent" = {
        enable = true;
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib/bluetooth"
          "/var/lib/boltd"
          "/var/lib/nixos"
          "/var/lib/systemd"
          "/var/lib/fprint"
          "/var/lib/NetworkManager"
          "/var/lib/iwd"
          "/var/lib/tailscale"
          "/var/lib/libvirt"
          "/var/lib/docker"
          "/var/lib/sbctl"
          "/var/cache/libvirt"
          "/etc/NetworkManager/system-connections"
        ];
        files = [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
        ];
      };

      # More stable than home-manager home.persistence."/persistent/home/${vars.userName}"
      environment.persistence."/persistent".users.${vars.userName} = {
        directories = [
          "code"
          "Documents"
          "Downloads"
          "Screenshots"
          (lib.removePrefix "/home/${vars.userName}/" config.customDirs.music)
          "go"
          ".cargo"
          ".claude/file-history"
          ".claude/plugins"
          ".claude/projects"
          ".claude/shell-snapshots"
          ".claude/statsig"
          ".claude/todos"
          ".config/chromium"
          ".config/google-chrome"
          ".config/cmus"
          ".config/gtk-3.0"
          ".config/discord"
          ".config/gh"
          ".config/github-copilot"
          ".config/pulse"
          ".config/syncthing"
          ".config/1Password"
          ".config/Slack"
          ".config/BeeperTexts"
          ".config/spotify"
          ".config/Todoist"
          ".config/sops"
          ".zoom"
          ".local/share/zoxide"
          ".local/share/mise"
          ".local/share/nvim"
          ".local/share/nautilus"
          ".local/share/syncthing"
          ".cache/cliphist"
          ".cache/cmus"
          ".local/state/nvim"
          ".local/state/wireplumber"
          ".local/share/libvirt"
          ".config/libvirt"
          ".ssh"
          ".mozilla"
          ".tmux/resurrect"
        ];
        files = [
          ".config/monitors.xml"
          ".zsh_history"
          ".claude.json"
          ".claude/.credentials.json"
          ".claude/history.jsonl"
        ];
      };

      fileSystems."/persistent".neededForBoot = true;
      fileSystems."/nix".neededForBoot = true;
      fileSystems."/var/log".neededForBoot = true;

      boot.initrd = {
        supportedFilesystems = [ "btrfs" ];

        postResumeCommands = lib.mkIf (!phase1Systemd) (lib.mkAfter wipeScript);

        systemd = lib.mkIf phase1Systemd {
          services.rollback = {
            description = "Rollback btrfs root subvolume to pristine state";
            wantedBy = [ "initrd.target" ];
            after = [ "systemd-cryptsetup@cryptroot.service" ];
            before = [ "sysroot.mount" ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = wipeScript;
          };
        };
      };
    };
}
