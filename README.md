# Setup

Based on [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) and https://github.com/dbeley/nixos-config and https://github.com/eh8/chenglab

## First time setup

### Linux
(reference: https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/no-os.md#installing-on-a-machine-with-no-operating-system)

Download the minimal ISO for your platform from the official NixOS website: https://nixos.org/download/

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

todo: look a cheng instructions

Install macos

Use the determinate nix installer .pkg

nix-shell -p git gh just vim darwin-nix

gh auth login  # use web browser option and do it on another machine
gh repo clone nix
cd nix
just deploy mbp-m1


## Impermanence Conflicts

If build fails with "Path X already exists", move conflicting files to persistence:
```bash
sudo mkdir -p /persistent/home/rich/<folder or file>
sudo mv /home/rich/.claude.json /persistent/home/rich/<folder or file>
sudo chown -R rich:users /persistent/home/rich/<folder or file>
just build
```

