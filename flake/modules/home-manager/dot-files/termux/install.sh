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
rm -rf ~/.shortcuts/scripts ~/.shortcuts/tasks
cp "$SCRIPT_DIR/shortcuts/"* ~/.shortcuts/
chmod +x ~/.shortcuts/*
echo "  Installed widget shortcuts"

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

rm -f ~/bin/ett
if [[ -L ~/Scripts ]]; then
    rm ~/Scripts
fi

if [[ -f ~/.bashrc ]]; then
    tmp_bashrc=$(mktemp)
    grep -v -E "alias ett='et-with-tunnel'|export TUNNEL_REMOTE_USER=rich|export TUNNEL_SSH_PORT=8022|export PATH=\"\$HOME/Scripts:\$PATH\"" ~/.bashrc > "$tmp_bashrc"
    mv "$tmp_bashrc" ~/.bashrc
fi

if [[ -f ~/.ssh/config ]]; then
    tmp_ssh_config=$(mktemp)
    awk '
        $0 == "Host um790" { skip = 1; next }
        skip && $0 == "    User rich" { skip = 0; next }
        { if (skip) skip = 0; print }
    ' ~/.ssh/config > "$tmp_ssh_config"
    mv "$tmp_ssh_config" ~/.ssh/config
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
