#!/usr/bin/env bash
# ==============================================================================
# Setup Customizable KDE Sliding Glass Dashboard Drawer
# ==============================================================================
# Automates the setup of the native sliding Nitro Sense glass drawer with
# hardware controls (Fans, Turbo, Battery Health, CPU/RAM stats) and shortcuts.
# ==============================================================================

set -e

# --- Colors for Output ---
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/dotfiles"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
USEFUL_SCRIPTS_DIR="$DOTFILES_DIR/useful-scripts"
DRAWER_DIR="$DOTFILES_DIR/sidebar-drawer"

TOGGLE_SCRIPT="$SCRIPTS_DIR/toggle-plasma-sidebar.sh"
DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
DESKTOP_ENTRY_FILE="$DESKTOP_ENTRY_DIR/toggle-plasma-sidebar.desktop"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/nitro-drawer.desktop"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR]${NC} This script should not be run as root."
    exit 1
fi

echo -e "${BLUE}[INFO]${NC} Starting Nitro Sense Sliding Drawer setup..."

# Ensure helper scripts have executable permissions
chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
chmod +x "$USEFUL_SCRIPTS_DIR"/*.sh 2>/dev/null || true

# Clean up any legacy thin left panels from Plasma 6
if command -v qdbus6 >/dev/null 2>&1 && pgrep -x "plasmashell" >/dev/null 2>&1; then
    echo -e "${BLUE}[INFO]${NC} Cleaning up legacy thin left panels..."
    CLEAN_JS='var pList = panels(); for (var i = pList.length - 1; i >= 0; --i) { if (pList[i].location === "left") pList[i].remove(); }'
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$CLEAN_JS" >/dev/null 2>&1 || true
fi

# Register Desktop entry for global shortcuts integration
echo -e "${BLUE}[INFO]${NC} Creating desktop entry for shortcut registration..."
mkdir -p "$DESKTOP_ENTRY_DIR"
cat <<EOF > "$DESKTOP_ENTRY_FILE"
[Desktop Entry]
Type=Application
Name=Toggle Nitro Sense Drawer
Comment=Toggle Sliding Glass Nitro Dashboard Drawer
Exec=$TOGGLE_SCRIPT
Icon=sidebar-show-symbolic
Terminal=false
Categories=Utility;
X-KDE-GlobalAccel-CommandShortcut=true
StartupNotify=false
EOF

# Register Autostart so the background drawer is ready on login
echo -e "${BLUE}[INFO]${NC} Creating autostart entry for background drawer daemon..."
mkdir -p "$AUTOSTART_DIR"
cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Name=Nitro Sense Drawer
Comment=Background daemon for sliding glass dashboard drawer
Exec=bash -c "nohup qml6 $DRAWER_DIR/main.qml >/dev/null 2>&1 &"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Register Global Shortcuts in KDE Plasma 6
if command -v kwriteconfig6 >/dev/null 2>&1; then
    echo -e "${BLUE}[INFO]${NC} Registering global shortcuts (NitroSense key / Meta+Alt+S)..."

    # Avoid conflict with kaccess screen reader shortcut
    kwriteconfig6 --file kglobalshortcutsrc --group "kaccess" --key "Toggle Screen Reader On and Off" "none,none,Toggle Screen Reader On and Off"

    # Register toggle shortcuts
    kwriteconfig6 --file kglobalshortcutsrc --group "services/toggle-plasma-sidebar.desktop" --key "_k_friendly_name" "Toggle Nitro Sense Drawer"
    kwriteconfig6 --file kglobalshortcutsrc --group "services/toggle-plasma-sidebar.desktop" --key "_launch" "Launch (1)\tMeta+Alt+S,none,Toggle Nitro Sense Drawer"

    # Reload KGlobalAccel shortcuts daemon
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KGlobalAccel /KGlobalAccel reloadConfig >/dev/null 2>&1 || true
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Global shortcuts registered."
fi

# Launch drawer process if not already running
if ! pgrep -f "qml6.*sidebar-drawer/main.qml" >/dev/null 2>&1; then
    echo -e "${BLUE}[INFO]${NC} Launching Nitro Sense Drawer..."
    nohup qml6 "$DRAWER_DIR/main.qml" >/dev/null 2>&1 &
fi

echo -e "${GREEN}✅ Nitro Sense Sliding Glass Dashboard Drawer setup completed successfully!${NC}"
