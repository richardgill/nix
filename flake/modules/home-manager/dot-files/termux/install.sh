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

if ! command -v autossh &> /dev/null; then
    echo "  Installing autossh..."
    pkg install -y autossh
else
    echo "  autossh already installed"
fi

if ! command -v sshd &> /dev/null; then
    echo "  Installing openssh..."
    pkg install -y openssh
else
    echo "  openssh already installed"
fi

# Create directories
mkdir -p ~/.termux
mkdir -p ~/.ssh

# Install termux config
cp "$SCRIPT_DIR/termux.properties" ~/.termux/
cp "$SCRIPT_DIR/colors.properties" ~/.termux/
echo "  Copied termux.properties and colors.properties"

if ! grep -q '^Host um790$' ~/.ssh/config 2>/dev/null; then
    cat >> ~/.ssh/config << 'EOF'

Host um790
    User rich
EOF
    echo "  Added SSH user mapping for um790"
else
    echo "  SSH user mapping for um790 already set"
fi

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

# Symlink shared Scripts dir so ett/tunnel-* and friends are available,
# matching the ~/Scripts layout used on NixOS/Mac home-manager
ln -sfn "$SCRIPT_DIR/../Scripts" ~/Scripts
echo "  Symlinked ~/Scripts -> $SCRIPT_DIR/../Scripts"

if ! grep -q 'PATH="$HOME/Scripts' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/Scripts:$PATH"' >> ~/.bashrc
    echo "  Added ~/Scripts to PATH in .bashrc"
else
    echo "  ~/Scripts already in PATH"
fi

if ! grep -q "alias ett=" ~/.bashrc 2>/dev/null; then
    echo "alias ett='et-with-tunnel'" >> ~/.bashrc
    echo "  Added ett alias to .bashrc"
else
    echo "  ett alias already set"
fi

if ! grep -q "TUNNEL_REMOTE_USER" ~/.bashrc 2>/dev/null; then
    echo 'export TUNNEL_REMOTE_USER=rich' >> ~/.bashrc
    echo "  Set TUNNEL_REMOTE_USER=rich in .bashrc"
else
    echo "  TUNNEL_REMOTE_USER already set"
fi

# Termux sshd listens on 8022, not 22 - tunnel-setup reads this as the
# fallback default so reverse tunnels target the right port
if ! grep -q "TUNNEL_SSH_PORT" ~/.bashrc 2>/dev/null; then
    echo 'export TUNNEL_SSH_PORT=8022' >> ~/.bashrc
    echo "  Set TUNNEL_SSH_PORT=8022 in .bashrc"
else
    echo "  TUNNEL_SSH_PORT already set"
fi

# Start sshd so reverse tunnels (beep, tunnel-open) can reach this device
if ! pgrep -x sshd > /dev/null; then
    sshd
    echo "  Started sshd on port 8022"
else
    echo "  sshd already running"
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

# Reminder about reverse-tunnel auth
if [[ ! -f ~/.ssh/authorized_keys ]]; then
    echo ""
    echo "For reverse tunnels (beep/tunnel-open) from remote hosts, add the"
    echo "remote's public key to ~/.ssh/authorized_keys on this device."
fi

echo ""
echo "Done! Connect with: ett <host>"
