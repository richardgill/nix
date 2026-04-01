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
# scripts/ = actual commands, tasks/ = singleton launchers (background, no terminal)
mkdir -p ~/.shortcuts/scripts ~/.shortcuts/tasks
rm -f ~/.shortcuts/um790
cp "$SCRIPT_DIR/scripts/"* ~/.shortcuts/scripts/
chmod +x ~/.shortcuts/scripts/*
cp "$SCRIPT_DIR/launchers/"* ~/.shortcuts/tasks/
chmod +x ~/.shortcuts/tasks/*
echo "  Installed widget shortcuts (singleton launchers)"

# Install nerd font via termux-nf
if [[ ! -f ~/.termux/font.ttf ]]; then
    echo "  Installing termux-nf for nerd fonts..."
    pkg install -y ncurses-utils
    curl -fsSL https://raw.githubusercontent.com/arnavgr/termux-nf/main/install.sh | bash
    echo "  Run 'getnf' to select and install a font (e.g., JetBrainsMono)"
else
    echo "  Font already installed"
fi

# Add ~/bin to PATH in .bashrc
mkdir -p ~/bin
if ! grep -q 'PATH="$HOME/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    echo "  Added ~/bin to PATH in .bashrc"
else
    echo "  ~/bin already in PATH"
fi

# Create update script in ~/bin
cat > ~/bin/update-termux << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e
cd ~/nix
git pull
./flake/modules/home-manager/dot-files/termux/install.sh
EOF
chmod +x ~/bin/update-termux
echo "  Created ~/bin/update-termux"

# Set SharedPreferences (settings not available in termux.properties)
PREFS_DIR="/data/data/com.termux/shared_prefs"
PREFS_FILE="$PREFS_DIR/com.termux_preferences.xml"
if [[ -f "$PREFS_FILE" ]]; then
    # Enable keep screen on
    if grep -q 'name="screen_always_on"' "$PREFS_FILE"; then
        sed -i 's|<boolean name="screen_always_on" value="false"/>|<boolean name="screen_always_on" value="true"/>|' "$PREFS_FILE"
    else
        sed -i 's|</map>|    <boolean name="screen_always_on" value="true" />\n</map>|' "$PREFS_FILE"
    fi
    echo "  Set screen_always_on=true in SharedPreferences"
else
    echo "  Warning: SharedPreferences file not found, set 'Keep screen on' manually via long-press menu"
fi

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
