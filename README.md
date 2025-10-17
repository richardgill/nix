
[![NixOS 25.05](https://img.shields.io/badge/NixOS-25.05-blue.svg?&logo=NixOS&logoColor=white)](https://nixos.org)

Nix config inspired by [Omarchy](https://omarchy.org/)'s system choices and [chenglab](https://github.com/eh8/chenglab)'s configuration structure.

**Uses Pragmatic Nix**: Simple config with plain `.conf` and `.json` files. Uses `.nix` features when they provide clear benefits.

## Features

This repo contains the Nix configurations for my NixOS machines, Macs and VMs.

- ❄️ Modern Nix flakes setup (currently 25.05)
- 🏠 [home-manager](https://github.com/nix-community/home-manager) manages dotfiles
  - Dot files are kept in plain `.conf` or `.json` where possible. [Mustache](https://mustache.github.io) for templating.
- 🔑 [sops-nix](https://github.com/Mic92/sops-nix) manages secrets
- 🔐 LUKS disk encryption with [remote unlock via SSH](#remote-luks-unlock)
- 💾 [disko](https://github.com/nix-community/disko): declarative disk partitioning with btrfs
- 🌬️ [impermanence](https://github.com/nix-community/impermanence) with btrfs
  - Filesystem wipes on reboot, keeping only folders that you explicitly persist in [your config](modules/system/nixos/headless/impermanence.nix)
  - Detect files which need persistence with `just find-impermanent`
- 📸 Btrfs snapshots for backup and recovery
- 💿 Full installation happens entirely inside the NixOS ISO (works on machines with small memory)
- ⚡️ `.justfile` contains useful aliases for frequent `nix` commands

## Folder structure

Configuration works simply by importing `.nix` files. There are no nix conditionals / logic - just import files with features you want on your machine.

Configuration is split onto folders:

- `headless/` - CLI-only, server environments
- `graphical/` - Desktop with GUI
- `optional/` - Opt-in features requiring explicit import the machine's `configuration.nix`.

```
├── flake.nix                 # Entry point - defines all machines in nixosConfigurations
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

Check [vars.nix](./vars.nix) and update your username, public keys etc.

## Installation - NixOS (Linux)

### Boot Nix ISO and enable SSH

Download the minimal (or graphical) ISO for your platform from the official [NixOS website](https://nixos.org/download/#nixos-iso). 

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
export ISO_IP="192.168.1.XXX"
ssh -t nixos@$ISO_IP
```

### Create a new Machine

Each NixOS machine has the following structure:

```
machines/<machine-name>/
├── configuration.nix
├── disko.nix # disk partitions
└── hardware-configuration.nix # auto generated
```

#### Create `hardware-configuration.nix`

Every machine needs a `machines/<machine-name>/hardware-configuration.nix`

You can generate hardware configuration directly from the live ISO:

```bash
ssh nixos@$ISO_IP "sudo nixos-generate-config --no-filesystems && cat /etc/nixos/hardware-configuration.nix"
```
Copy the configuration to: `machines/<machine-name>/hardware-configuration.nix` on your local machine.

Commit and push it to git.

#### Create disk partition configuration: `disko.nix`

Every NixOS machine needs a `machines/<machine>/disko.nix` which defines its disk partitions.

You can copy an existing `disko.nix` from another machine, such as [um790/disko.nix](machines/um790/disko.nix).

```
# disko.nix
...
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; <<< you need to update this
...
```

You need to update your device to match the disk device path of the new machine. You can find the disk device path for your machine directly from the live ISO by running:

```bash
ssh nixos@$ISO_IP "sudo fdisk -l"
```

Commit `machines/<machine>/disko.nix` and push it to git.

#### Create `configuration.nix`

1. **Copy an existing configuration** as a starting point:
   - Example: [um790/configuration.nix](machines/um790/configuration.nix)

2. **Import a base module** depending on your machine type:
   - [`modules/system/nixos/headless`](modules/system/nixos/headless/default.nix) — for server machines
   - [`modules/system/nixos/graphical`](modules/system/nixos/graphical/default.nix) — for GUI machines (includes headless features)

3. **Add optional features** as needed:
   - Example: `modules/system/nixos/headless/optional/thunderbolt.nix`

#### Add machine to `flake.nix`

After creating your machine configuration files, add the machine to the `nixosHosts` section in `flake.nix`:

```nix
nixosHosts = {
  ...
  your-machine-name = {
    system = "x86_64-linux";  # or "aarch64-linux" for ARM
    path = ./machines/your-machine-name/configuration.nix;
  };
  ...
};
```

The machine name should match your hostname. Commit and push this change to git.

### Install

The install happens directly from the live ISO. It does not require a large amount of ram to work. 

During the install you'll be prompted to set a password for your user and for LUKS encryption:

```bash
# Using public repository without token (if already authenticated)
scp scripts/clone-and-install.sh nixos@$ISO_IP:/tmp/ && \
  ssh -t nixos@$ISO_IP "/tmp/clone-and-install.sh richardgill/nix"
```

```bash
# Using private repository with github token
scp scripts/clone-and-install.sh nixos@$ISO_IP:/tmp/ && \
  ssh -t nixos@$ISO_IP "/tmp/clone-and-install.sh richardgill/nix-private $(gh auth token)"
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

## Remote LUKS unlock

You can unlock LUKS locally, or via SSH:

```bash
ssh root@<machine-ip> -p 2222
```

You'll be prompted to enter the LUKS passphrase. The machine will continue booting and you can SSH normally: 

```bash
ssh username@<machine-ip> 
```

Configuration: [remote-unlock.nix](modules/system/nixos/headless/remote-unlock.nix)

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

