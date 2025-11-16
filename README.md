My opinionated Nix config inspired by [Omarchy](https://omarchy.org/)'s system choices and [chenglab](https://github.com/eh8/chenglab)'s configuration structure.

Pragmatic Nix: Simple config with plain `.conf` and `.json` files. Uses `.nix` features when they provide clear benefits.

Dotfiles: [modules/home-manager/dot-files](modules/home-manager/dot-files)

## Features

- Modern Nix flakes
- [home-manager](https://github.com/nix-community/home-manager) manages dotfiles
  - Dotfiles are kept in plain `.conf` or `.json` where possible. [Mustache](https://mustache.github.io) for templating.
- LUKS disk encryption:
  - [remote unlock via SSH](#remote-unlock-over-ssh)
  - [Secure Boot](#luks-auto-unlock-with-secure-boot--tpm2) with TPM2 auto-unlock of LUKS
- [disko](https://github.com/nix-community/disko): declarative disk partitioning with btrfs
- [impermanence](https://github.com/nix-community/impermanence) with btrfs
  - Filesystem wipes on reboot, keeping only folders that you explicitly persist in [your config](modules/system/nixos/headless/impermanence.nix#L84)
  - Detect files which need persistence with `just find-impermanent`
- Full installation happens entirely inside the NixOS ISO (works on machines with small memory)
- [sops-nix](https://github.com/Mic92/sops-nix) manages secrets
- Btrfs snapshots for backup and recovery of user data
- `.justfile` contains useful aliases for frequent `nix` commands

## Folder structure

Configuration works simply by importing `.nix` files. There is minimal Nix conditionals / logic - just import files with features you want on your machine.

Configuration is split onto folders:

- `headless/` - CLI-only, server environments
- `graphical/` - Desktop with GUI
- `optional/` - Opt-in features requiring explicit import the machine's `configuration.nix`.
- `shared/` - Cross-platform configs (works on both NixOS and macOS)

```
├── flake.nix                 # Entry point - defines all machines in nixosConfigurations
├── vars.nix                  # Shared variables (username, etc.)
├── .justfile                 # Run `just --list` to see the commands
│
├── machines/                 # Per-machine configurations
│   ├── nixos-machine-1/
│   │   ├── configuration.nix           # Imports shared disko module
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

▶️ **[Video walkthrough of the installation process](https://www.youtube.com/watch?v=Iyz4PolCPPY)**

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
ssh nixos@$ISO_IP
```

### Create a new Machine

Each NixOS machine has the following structure:

```
machines/<machine-name>/
├── configuration.nix           # Machine config
└── hardware-configuration.nix  # Auto-generated hardware config
```

#### Create `hardware-configuration.nix`

Every machine needs a `machines/<machine-name>/hardware-configuration.nix`

You can generate hardware configuration directly from the live ISO:

```bash
ssh nixos@$ISO_IP "sudo nixos-generate-config --no-filesystems && cat /etc/nixos/hardware-configuration.nix"
```
Copy the configuration to: `machines/<machine-name>/hardware-configuration.nix` on your local machine.

Commit and push it to git.

#### Create `configuration.nix`

1. **Copy an existing configuration** as a starting point:
   - Example: [um790/configuration.nix](machines/nixos/x86_64/um790/configuration.nix)

2. **Import the disko module** with your disk configuration:
   ```nix
   (import ../../../../modules/system/nixos/headless/disko.nix {
     device = "/dev/nvme0n1";        # Your primary disk device (find with: lsblk)
     resumeOffset = "533760";        # For hibernate support (get with: btrfs inspect-internal map-swapfile -r /.swapvol/swapfile)
     swapSize = "16G";               # Swap file size (see https://itsfoss.com/swap-size)
     isSsd = true;                   # Enable SSD optimizations
   })
   ```

   **Finding your device name:**
   ```bash
   ssh nixos@$ISO_IP "lsblk"  # List all block devices from the NixOS ISO
   # Common device names: /dev/nvme0n1 (NVMe SSD), /dev/sda (SATA/SCSI), /dev/vda (VM)
   ```

3. **Import a base module** depending on your machine type:
   - [`modules/system/nixos/headless`](modules/system/nixos/headless/default.nix) — for server machines
   - [`modules/system/nixos/graphical`](modules/system/nixos/graphical/default.nix) — for GUI machines (includes headless features)

4. **Add optional features** as needed:
   - Example: `modules/system/nixos/headless/optional/thunderbolt.nix`

### Install

The install happens directly from the live ISO. It does not require a large amount of RAM to work. 

During the install you'll be prompted to set a password for your user and for LUKS encryption:

```bash
# Using public repository without token (if already authenticated)
scp scripts/clone-and-install.sh nixos@$ISO_IP:/tmp/ && \
  ssh nixos@$ISO_IP "/tmp/clone-and-install.sh richardgill/nix"
```

```bash
# Using private repository with github token
scp scripts/clone-and-install.sh nixos@$ISO_IP:/tmp/ && \
  ssh nixos@$ISO_IP "/tmp/clone-and-install.sh richardgill/nix-private $(gh auth token)"
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

## Useful commands

Install `just` to access the simple aliases below.

### Locally deploy changes

```bash
just switch
```

## Setup LUKS

By default you can unlock LUKS locally

### Remote unlock over SSH

```bash
ssh root@<machine-ip> -p 2222
```

You'll be prompted to enter the LUKS passphrase. The machine will continue booting and you can SSH normally: 

```bash
ssh username@<machine-ip> 
```

Configuration: [remote-unlock.nix](modules/system/nixos/headless/remote-unlock.nix)

## LUKS auto unlock with Secure Boot + TPM2

Import [modules/system/nixos/headless/optional/secure-boot.nix](modules/system/nixos/headless/optional/secure-boot.nix) in your machine's `configuration.nix`, then follow the setup instructions in that file.

## Impermanence

This configuration uses btrfs with impermanence, where the root filesystem is reset on every boot. Only explicitly declared files and directories in `/persistent` survive reboots.

When adding new persistence directories/files, they need to be added in `modules/system/nixos/headless/impermanence.nix` (for actual persistence)

### Find impermanent files

Find files that have been written in ephemeral storage but aren't in your impermanence config:

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
- [Great beginner friendly introduction to NixOS and flakes](https://nixos-and-flakes.thiscute.world/)

