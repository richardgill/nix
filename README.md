Based on [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) and https://github.com/dbeley/nixos-config and https://github.com/eh8/chenglab

# Setup

## First time setup

### Linux
(reference: https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/no-os.md#installing-on-a-machine-with-no-operating-system)

Download the minimal ISO for your platform from the official NixOS website: https://nixos.org/download/ (also works in graphical, just run the steps below in a terminal)

Set a password to enable ssh: `passwd`

find the ip address with: `ip addr show`

On your local machine set `ISO_IP="1.2.3.4"`

Confirm you can ssh in: `ssh -t nixos@$ISO_IP`

#### (optional) Update disks
Find disk name and update relevant machine `machines/<machine>/disko.nix` if necessary and commit and push it.
```
ssh nixos@$ISO_IP "sudo fdisk -l"
```

#### (optional) Update hardware configuration
Generate hardware configuration for the target machine. Copy output to machines/<machine>/hardware-configuration.nix if necessary and commit and push it.
```
ssh nixos@$ISO_IP "sudo nixos-generate-config --no-filesystems && cat /etc/nixos/hardware-configuration.nix"
```

#### Install

The install happens on the machine running the iso over ssh, so you don't need another machine with nix to do it.

Note: You'll be prompted to set a password for your user and for LUKS.

```
scp scripts/clone-and-install.sh nixos@$ISO_IP:/tmp/ && \
 ssh -t nixos@$ISO_IP "/tmp/clone-and-install.sh $(gh auth token)"
```

### Mac

- Install a fresh copy of MacOS
- Install the [Determinate Systems Nix installer](https://docs.determinate.systems/) for Mac
- nix-shell -p git gh just

Then:

```
gh auth login  # use web browser option and do it on another machine where you're logged into github
gh repo clone nix-private
cd nix-private
just mac-install
```

sops will fail, you need to place you sops key in ~/.config/sops/age/keys.txt (login to 1password to find it)

rebuild with `just switch`

Go to System Settings > Keyboard > Keyboard Shortcuts and aggressively turn off all shortcuts to prevent conflicts

If Homebrew casks are blocked as malicious, go to System Settings → Privacy & Security and click "Open Anyway"

## Impermanence Conflicts

If build fails with "Path X already exists", move conflicting files to persistence:
```bash
sudo mkdir -p /persistent/home/rich/<folder or file>
sudo mv /home/rich/.claude.json /persistent/home/rich/<folder or file>
sudo chown -R rich:users /persistent/home/rich/<folder or file>
just build
```

