#!/usr/bin/env nix-shell
#! nix-shell -i bash -p git gh jq gum just

set -e

echo "Starting macOS nix-darwin setup..."
echo ""

echo "Installing Xcode Command Line Tools..."
xcode-select --install
echo ""
read -p "Press enter once installation is complete..."
echo ""

echo "Checking SSH host keys for SOPS..."
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    echo "Generating SSH host keys..."
    sudo ssh-keygen -A
    echo "SSH host keys generated ✓"
else
    echo "SSH host keys already exist ✓"
fi
echo ""

echo "Renaming conflicting /etc files if they exist..."
for file in /etc/zshrc /etc/zprofile; do
    if [ -f "$file" ] && [ ! -f "$file.before-nix-darwin" ]; then
        echo "Moving $file to $file.before-nix-darwin"
        sudo mv "$file" "$file.before-nix-darwin"
    fi
done
echo "File conflicts resolved ✓"
echo ""

# https://github.com/DeterminateSystems/nix-installer/issues/1665
# nix determinate has wrong permissions for ~/.local
echo "Creating home-manager profile directory..."
sudo chown -R $USER:staff ~/.local 2>/dev/null || true
echo "Profile directory permissions corrected ✓"
echo ""

echo "Getting available darwin configurations..."
AVAILABLE_MACHINES=$(nix eval --json .#darwinConfigurations --apply builtins.attrNames | jq -r '.[]')

if [ -z "$AVAILABLE_MACHINES" ]; then
    echo "ERROR: No darwin configurations found in flake!"
    exit 1
fi

echo "Select darwin configuration:"
MACHINE=$(echo "$AVAILABLE_MACHINES" | gum choose)

if [ -z "$MACHINE" ]; then
    echo "No machine selected. Exiting."
    exit 1
fi

echo "Selected machine: $MACHINE ✓"
echo ""

echo "Building and activating nix-darwin configuration for $MACHINE..."
just switch "$MACHINE"

echo ""
echo "nix-darwin installation complete!"
echo "Configuration has been activated."
