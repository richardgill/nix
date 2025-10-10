{
  lib,
  hostName,
  vars,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

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
      "/var/lib/systemd/coredump"
      "/var/lib/fprint"
      "/var/lib/NetworkManager"
      "/var/lib/iwd"
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
      "go"
      ".cargo"
      ".claude/file-history"
      ".claude/plugins"
      ".claude/projects"
      ".claude/shell-snapshots"
      ".claude/statsig"
      ".claude/todos"
      ".config/chromium"
      ".config/gtk-3.0"
      ".config/discord"
      ".config/gh"
      ".config/pulse"
      ".config/1Password"
      ".config/Slack"
      ".config/BeeperTexts"
      ".config/spotify"
      ".zoom"
      ".local/share/zoxide"
      ".local/share/mise"
      ".local/share/nvim"
      ".local/share/nautilus"
      ".local/share/cliphist"
      ".local/state/nvim"
      ".local/state/wireplumber"
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

  # Impermanence
  boot.initrd.postResumeCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/mapper/root_vg_${hostName} /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/persistent/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/persistent/old_roots/$timestamp/"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/persistent/old_roots/ -mindepth 1 -maxdepth 1 -mtime +1); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';
}
