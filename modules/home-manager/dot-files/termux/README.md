# Termux Setup

Connecting to NixOS from Android Termux app via Eternal Terminal.

Install Termux from f-droid, not play store.

## Install

```bash
# Install git
pkg install git

# Clone the repo
git clone https://github.com/richardgill/nix ~/nix

# Run install script
cd nix
./modules/home-manager/dot-files/termux/install.sh

# Install a nerd font (run after install.sh)
getnf -i JetBrainsMono
```

## First-time SSH key setup

```bash
# Generate key
ssh-keygen -t ed25519

# Copy to NixOS
ssh-copy-id rich@hostname
```

## Connect

```bash
et rich@hostname
```

## Files

- `install.sh` — installs ET, fonts, and termux config
- `termux.properties` — extra keys optimized for tmux
- `colors.properties` — Tokyo Night color scheme
