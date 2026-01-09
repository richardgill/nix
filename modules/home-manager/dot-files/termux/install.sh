#!/data/data/com.termux/files/usr/bin/bash
# Install Termux config from nix-private repo
# Run this in Termux after cloning/pulling the repo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Termux configuration..."

if ! command -v et &> /dev/null; then
    echo "  Installing Eternal Terminal..."
    pkg install -y et
else
    echo "  Eternal Terminal already installed"
fi

# Create directories
mkdir -p ~/.termux
mkdir -p ~/.ssh

# Install termux config
cp "$SCRIPT_DIR/termux.properties" ~/.termux/
cp "$SCRIPT_DIR/colors.properties" ~/.termux/
echo "  Copied termux.properties and colors.properties"

# Install widget shortcuts (for Termux:Widget from F-Droid)
mkdir -p ~/.shortcuts
cp "$SCRIPT_DIR/um790" ~/.shortcuts/
chmod +x ~/.shortcuts/um790
echo "  Installed ~/.shortcuts/um790 (add Termux:Widget to home screen)"

# Install nerd font via termux-nf
if [[ ! -f ~/.termux/font.ttf ]]; then
    echo "  Installing termux-nf for nerd fonts..."
    pkg install -y ncurses-utils
    curl -fsSL https://raw.githubusercontent.com/arnavgr/termux-nf/main/install.sh | bash
    echo "  Run 'getnf' to select and install a font (e.g., JetBrainsMono)"
else
    echo "  Font already installed"
fi

# Create update script in ~/bin
mkdir -p ~/bin
cat > ~/bin/update-termux << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e
cd ~/nix
git pull
./modules/home-manager/dot-files/termux/install.sh
EOF
chmod +x ~/bin/update-termux
echo "  Created ~/bin/update-termux"

# Reload settings
termux-reload-settings
echo "Settings reloaded!"

# Reminder about SSH key (still needed for ET initial auth)
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
    echo ""
    echo "No SSH key found. Generate one with:"
    echo "  ssh-keygen -t ed25519"
    echo "  ssh-copy-id rich@<host>"
fi

echo ""
echo "Done! Connect with: et <host>"
