
[![nixos 25.05](https://img.shields.io/badge/NixOS-25.05-blue.svg?&logo=NixOS&logoColor=white)](https://nixos.org)

Opinionated Nix config inspired by [Omarchy](https://omarchy.org/), [chenglab](https://github.com/eh8/chenglab) and [others](#acknowledgments).

## Highlights

This repo contains the Nix configurations for my NixOS machines, Macs and VMs.

- ❄️ Modern Nix flakes setup (currently 25.05)
- 🏠 [home-manager](https://github.com/nix-community/home-manager) manages dotfiles
  - Dot files are kept in plain `.conf` or `.json` where possible. Mustache for templating.
- 🍎 [nix-darwin](https://github.com/LnL7/nix-darwin) for Macs
- 🔑 [sops-nix](https://github.com/Mic92/sops-nix) manages secrets
- 💾 [disko](https://github.com/nix-community/disko) handles declarative disk partitioning with btrfs
- 🌬️ [impermanence](https://github.com/nix-community/impermanence) with btrfs root on ephemeral storage
  - Find files that are changing with `just find-impermanent`
- 📸 Btrfs snapshots for backup and recovery
- 💿 Full installation happens entirely inside the NixOS ISO
- ⚡️ `.justfile` contains useful aliases for frequent `nix` commands

## Folder structure

Configuration is modular - just import what you need:

- `optional/` - Opt-in features requiring explicit import
- `headless/` - CLI-only, server environments
- `graphical/` - Desktop with GUI

```
├── flake.nix                 # Entry point
├── vars.nix                  # Shared variables (username, etc.)
├── .justfile                 # Run `just --list` to see the commands
│
├── machines/                 # Per-machine configurations
│   ├── nixos-machine-1/
│   │   ├── configuration.nix
│   │   ├── disko.nix                   # Disk partitioning (NixOS only)
│   │   └── hardware-configuration.nix
│   └── mac-1/
│       ├── configuration.nix
│       └── hardware-configuration.nix  
│
├── modules/
│   ├── system/               # System-level configurations
│   │   ├── shared/           # Cross-platform system configs
│   │   │   ├── headless/     
│   │   │   └── graphical/   
│   │   ├── nixos/            # NixOS-specific system configs
│   │   │   ├── headless/
│   │   │   │   └── optional/ 
│   │   │   └── graphical/
│   │   │       └── optional/ 
│   │   └── mac/              # Mac-specific system configs
│   │
│   └── home-manager/         # User-level configurations
│       ├── dot-files/        # Raw config files (nvim, tmux, etc.)
│       ├── shared/           
│       │   ├── headless/     
│       │   └── graphical/    
│       ├── nixos/            # NixOS-specific home-manager configs
│       │   ├── headless/
│       │   └── graphical/
│       └── mac/              # Mac-specific home-manager configs
│
├── .sops.yaml                # sops-nix secrets configuration 
├── secrets/                  # Encrypted secrets (via sops-nix)
└── utils/                    # Utilities
```

## Getting started


### NixOS (Linux)

> [!IMPORTANT]
Installation happens entirely within the ISO environment.

Download the minimal ISO for your platform from the official NixOS website: https://nixos.org/download/

Boot from the ISO, then set a password to enable SSH:

```bash
passwd
```

Find the IP address:

```bash
ip addr show
```

On your local machine where you've checked out this repo, set the ISO IP and confirm SSH access:

```bash
export ISO_IP="1.2.3.4"
ssh -t nixos@$ISO_IP
```

#### (Optional) Update hardware configuration

Generate hardware configuration for the target machine:

```bash
ssh nixos@$ISO_IP "sudo nixos-generate-config --no-filesystems && cat /etc/nixos/hardware-configuration.nix"
```

Copy output to `machines/<machine>/hardware-configuration.nix` if necessary and commit and push it.

#### (Optional) Update disks

Find disk name and update relevant machine `machines/<machine>/disko.nix` if necessary:

```bash
ssh nixos@$ISO_IP "sudo fdisk -l"
```

#### Install

The install happens on the machine running the ISO over SSH. You'll be prompted to set a password for your user and for LUKS encryption:

```bash
scp scripts/clone-and-install.sh nixos@$ISO_IP:/tmp/ && \
  ssh -t nixos@$ISO_IP "/tmp/clone-and-install.sh $(gh auth token)"
```

### macOS

On macOS, first install the [Determinate Systems Nix installer](https://docs.determinate.systems/):

Then install the configuration:

```bash
nix-shell -p git gh just
gh auth login
gh repo clone nix-private
cd nix-private
just mac-install
```

Place your sops key in `~/.config/sops/age/keys.txt` (retrieve from 1Password).

Rebuild with `just switch`.

**Additional macOS setup:**
- Go to System Settings → Keyboard → Keyboard Shortcuts and disable conflicting shortcuts
- If Homebrew casks are blocked, go to System Settings → Privacy & Security and click "Open Anyway"

## Useful commands 🛠️

Install `just` to access the simple aliases below.

### Locally deploy changes

```bash
just switch
```


## Impermanence

This configuration uses btrfs with impermanence, where the root filesystem is reset on every boot. Only explicitly declared files and directories in `/persistent` survive reboots.

When adding new persistence directories/files, they need to be added in `modules/system/nixos/headless/impermanence.nix` (for actual persistence)

### Find impermanent files

Find files that exist in ephemeral storage but aren't persisted:

```bash
just find-impermanent
```
### Switching fails

If switching to latest version fails with "Path X already exists", move conflicting files to persistence first:

```bash
sudo mkdir -p /persistent/home/$USER/<folder>
sudo mv /home/$USER/<file> /persistent/home/$USER/<folder>/
sudo chown -R $USER:users /persistent/home/$USER/<folder>
just build
```

## Temporarily Edit Configs Without Rebuilding

To quickly test config changes (e.g., nvim) without rebuilding:

```bash
rm ~/.config/nvim
ln -s ~/code/nix-private/modules/home-manager/dot-files/nvim ~/.config/nvim
```

Now edits go directly to your source files. When done testing, restore the managed version:

```bash
rm ~/.config/nvim
sudo nixos-rebuild switch
```

This works for any home-manager managed config file.

## Acknowledgments

- [eh8/chenglab](https://github.com/eh8/chenglab) - Primary inspiration for this configuration structure
- [Omarchy](https://omarchy.org/) - Opinionated Linux setup inspiration
- [dbeley/nixos-config](https://github.com/dbeley/nixos-config) - Btrfs impermanence implementation
- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) - Initial starter configuration
- [An outstanding beginner friendly introduction to NixOS and flakes](https://nixos-and-flakes.thiscute.world/)

