#!/usr/bin/env nix-shell
#! nix-shell -i bash -p git jq gum

set -e

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <REPO> [GH_TOKEN]"
    exit 1
fi

REPO="$1"
GH_TOKEN="$2"
GITHUB_REPO_URL="https://${GH_TOKEN:+$GH_TOKEN@}github.com/$REPO.git"

echo "Setting up user password..."
while true; do
    PASSWORD=$(gum input --password --placeholder "Enter password for user $USERNAME")
    PASSWORD_CONFIRM=$(gum input --password --placeholder "Confirm password")

    if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
        echo "Password confirmed ✓"
        break
    else
        echo "Passwords do not match. Please try again."
    fi
done
# Clean up any previous installation attempts that may have left mounted devices
sudo umount -R /mnt 2>/dev/null || true
sudo swapoff /mnt/swapfile 2>/dev/null || true

echo "Setting up repository clone and authentication..."

# Clone the repository
echo "Cloning NixOS configuration..."
[ -d /tmp/nixos-config ] && rm -rf /tmp/nixos-config
git clone "$GITHUB_REPO_URL" /tmp/nixos-config
cd /tmp/nixos-config

echo ""
echo "Repository cloned successfully to /tmp/nixos-config"
echo ""

echo "Getting available machine configurations..."
AVAILABLE_MACHINES=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in builtins.concatStringsSep "\n" (builtins.attrNames flake.nixosConfigurations)')

if [ -z "$AVAILABLE_MACHINES" ]; then
    echo "ERROR: No machine configurations found in flake!"
    exit 1
fi

echo "Select machine configuration:"
MACHINE=$(echo "$AVAILABLE_MACHINES" | gum choose)

if [ -z "$MACHINE" ]; then
    echo "No machine selected. Exiting."
    exit 1
fi

echo "Selected machine: $MACHINE ✓"
echo ""

echo "Getting username from flake..."
USERNAME=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.vars.userName')
echo "Username: $USERNAME"
echo ""


echo "Installing NixOS for $MACHINE"

# We run disko standalone so we can use the new mount so we don't run out of disk space
echo "Running disko for $MACHINE"
sudo nix --extra-experimental-features nix-command --extra-experimental-features flakes run github:nix-community/disko -- --mode destroy,format,mount --flake ".#$MACHINE" --show-trace

# Create the swap file on the mounted partition so the nix store (tmpfs in ram) doesn't run out of space
echo "Setting up swap so install iso doesn't run out of disk space (which is tmpfs in ram) debug with: df -h && swapon -s"
sudo mkswap -U clear --size 8G --file /mnt/swapfile
sudo swapon /mnt/swapfile

echo ""
echo "Setting up user password file..."
echo "$PASSWORD" | mkpasswd -m sha-512 -s | sudo tee /mnt/persistent/passwd_$USERNAME > /dev/null
sudo chown root:root /mnt/persistent/passwd_$USERNAME
echo "Password file created ✓"
echo ""
echo "Generating SSH host key for SOPS and initrd LUKS decrypt..."
sudo mkdir -p /mnt/nix/secret/initrd
sudo chmod 0700 /mnt/nix/secret
sudo ssh-keygen -t ed25519 -N "" -C "" -f /mnt/nix/secret/initrd/ssh_host_ed25519_key
echo "SSH host key generated successfully"

echo ""
echo "Converting SSH key to age format..."
AGE_KEY=$(sudo nix-shell --extra-experimental-features flakes -p ssh-to-age --run 'cat /mnt/nix/secret/initrd/ssh_host_ed25519_key.pub | ssh-to-age')
echo "Age public key: $AGE_KEY"

echo ""
echo "======================================================================"
echo "                    SOPS CONFIGURATION UPDATE REQUIRED"
echo "======================================================================"
echo ""
echo "New age key for machine '$MACHINE':"
echo "$AGE_KEY"
echo ""
echo "INSTRUCTIONS:"

echo "1. Update .sops.yaml with the new host's age key:"
echo "   keys:"
echo "     - &$MACHINE $AGE_KEY # Add this line"
echo "   creation_rules:"
echo "     - path_regex: secrets/[^/]+(\\.(yaml|json|env|ini|conf))?$"
echo "       key_groups:"
echo "         - age:"
echo "             - *$MACHINE  # Add this line"
echo ""
echo "2. Re-encrypt secrets:"
echo "   sops updatekeys secrets/secrets.yaml"
echo ""
echo "3. Commit and push changes."
echo ""
echo "======================================================================"
echo "This script will then pull your changes here before finishing installation"
echo "Press Enter when you have completed these steps..."
read -r

echo "git pull'ing repository to get latest changes..."
git pull "$GITHUB_REPO_URL"
echo "Repository sync complete."

echo "Running NixOS installation for machine '$MACHINE'..."
echo ""
# TMPDIR being inside the mount prevents device out of space in live ISO
TMPDIR=/mnt/tmp sudo nixos-install --no-root-passwd --root /mnt --flake ".#$MACHINE"

echo ""
echo "Installation complete!"
read -p "Reboot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "Reboot skipped. Remember to reboot manually when ready."
fi
