#!/usr/bin/env bash
# fs-diff.sh
set -euo pipefail

sudo btrfs subvolume find-new / 0 |
sed '$d' |
cut -f17- -d' ' |
sort |
uniq |
while read path; do
  path="/$path"

  # Skip if symbolic link
  if [ -L "$path" ]; then
    continue
  fi

  # Skip if directory
  if [ -d "$path" ]; then
    continue
  fi

  # Skip persisted system directories and files
  case "$path" in
    /var/log/* | \
    /var/lib/bluetooth/* | \
    /var/lib/boltd/* | \
    /var/lib/nixos/* | \
    /var/lib/systemd/coredump/* | \
    /var/lib/fprint/* | \
    /var/lib/NetworkManager/* | \
    /var/lib/iwd/* | \
    /etc/NetworkManager/system-connections/* | \
    /var/lib/colord/* | \
    /etc/machine-id | \
    /etc/ssh/ssh_host_ed25519_key.pub | \
    /etc/ssh/ssh_host_ed25519_key | \
    /etc/ssh/ssh_host_rsa_key.pub | \
    /etc/ssh/ssh_host_rsa_key | \
    /persistent/* | \
    /nix/* )
      continue
      ;;
  esac

  # Skip persisted user directories and files
  case "$path" in
    /home/*/code/* | \
    /home/*/Documents/* | \
    /home/*/Downloads/* | \
    /home/*/Screenshots/* | \
    /home/*/go/* | \
    /home/*/.cargo/* | \
    /home/*/.config/chromium/* | \
    /home/*/.config/gtk-3.0/* | \
    /home/*/.config/discord/* | \
    /home/*/.config/1Password/* | \
    /home/*/.config/Slack/* | \
    /home/*/.config/BeeperTexts/* | \
    /home/*/.config/spotify/* | \
    /home/*/.zoom/* | \
    /home/*/.config/alacritty/* | \
    /home/*/.config/cmus/* | \
    /home/*/.config/ghostty/* | \
    /home/*/.config/git/* | \
    /home/*/.config/gh/* | \
    /home/*/.config/hypr/* | \
    /home/*/.config/bat/* | \
    /home/*/.config/delta/* | \
    /home/*/.config/yazi/* | \
    /home/*/.config/waybar/* | \
    /home/*/.config/wallpapers/* | \
    /home/*/.config/nvim/* | \
    /home/*/.config/walker/* | \
    /home/*/.config/tmux/* | \
    /home/*/.config/mako/* | \
    /home/*/.config/mise/* | \
    /home/*/.config/oh-my-posh/* | \
    /home/*/.config/op/* | \
    /home/*/.config/opencode/* | \
    /home/*/.config/pulse/* | \
    /home/*/.config/ripgrep/* | \
    /home/*/.config/rofi/* | \
    /home/*/.config/satty/* | \
    /home/*/.config/sesh/* | \
    /home/*/.config/swayosd/* | \
    /home/*/.codex/* | \
    /home/*/.local/share/zoxide/* | \
    /home/*/.local/share/mise/* | \
    /home/*/.local/share/nvim/* | \
    /home/*/.local/share/nautilus/* | \
    /home/*/.local/share/cliphist/* | \
    /home/*/.local/state/nvim/* | \
    /home/*/.local/state/wireplumber/* | \
    /home/*/.ssh/* | \
    /home/*/.mozilla/* | \
    /home/*/.tmux/resurrect/* | \
    /home/*/Scripts/* | \
    /home/*/.config/monitors.xml | \
    /home/*/.zsh_history | \
    /home/*/.zshenv | \
    /home/*/.zshrc | \
    /home/*/.lesskey | \
    /home/*/.gitconfig | \
    /home/*/.claude.json | \
    /home/*/.claude/.credentials.json | \
    /home/*/.claude/history.jsonl | \
    /home/*/.claude/file-history/* )
      continue
      ;;
  esac

  # Skip ephemeral files (cache, temp, etc.)
  case "$path" in
    /home/*/.cache/* | \
    /tmp/node-compile-cache/* | \
    /tmp/mise/* )
      continue
      ;;
  esac

  echo "$path"
done
