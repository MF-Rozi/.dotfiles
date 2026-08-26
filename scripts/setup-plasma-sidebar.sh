#!/usr/bin/env bash
# ==============================================================================
# Setup Customizable KDE Plasma 6 Left Vertical Sidebar Panel
# ==============================================================================
# Automates the creation and configuration of a vertical auto-hiding sidebar
# panel in KDE Plasma 6 with Acer Nitro Fan/Battery controls and hotkeys.
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
PLASMOIDS_SRC_DIR="$DOTFILES_DIR/plasmoids"
PLASMOIDS_DEST_DIR="$HOME/.local/share/plasma/plasmoids"

JS_LAYOUT_FILE="$SCRIPTS_DIR/setup-plasma-sidebar.js"
TOGGLE_SCRIPT="$SCRIPTS_DIR/toggle-plasma-sidebar.sh"
STATUS_SCRIPT="$SCRIPTS_DIR/get-nitro-status.sh"
DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
DESKTOP_ENTRY_FILE="$DESKTOP_ENTRY_DIR/toggle-plasma-sidebar.desktop"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR]${NC} This script should not be run as root."
    exit 1
fi

echo -e "${BLUE}[INFO]${NC} Starting KDE Plasma 6 Sidebar setup..."

# Ensure helper scripts have executable permissions
chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
chmod +x "$USEFUL_SCRIPTS_DIR"/*.sh 2>/dev/null || true

# Install custom plasmoids (e.g. Nitro Control)
if [ -d "$PLASMOIDS_SRC_DIR" ]; then
    echo -e "${BLUE}[INFO]${NC} Installing custom plasmoids..."
    mkdir -p "$PLASMOIDS_DEST_DIR"
    for plasmoid in "$PLASMOIDS_SRC_DIR"/*; do
        if [ -d "$plasmoid" ]; then
            p_name=$(basename "$plasmoid")
            ln -sfn "$plasmoid" "$PLASMOIDS_DEST_DIR/$p_name"
            echo -e "${GREEN}[INFO]${NC} Linked plasmoid: $p_name"
        fi
    done
fi

# Check for qdbus / qdbus6
if command -v qdbus6 >/dev/null 2>&1; then
    QDBUS_CMD="qdbus6"
elif command -v qdbus >/dev/null 2>&1; then
    QDBUS_CMD="qdbus"
else
    echo -e "${YELLOW}[WARNING]${NC} Neither 'qdbus6' nor 'qdbus' found. Skipping live panel setup."
    exit 0
fi

# Check if plasmashell is running
if ! pgrep -x "plasmashell" >/dev/null 2>&1; then
    echo -e "${YELLOW}[WARNING]${NC} KDE Plasma shell is not currently running. Skipping live injection."
else
    if [ ! -f "$JS_LAYOUT_FILE" ]; then
        echo -e "${RED}[ERROR]${NC} Layout script not found at '$JS_LAYOUT_FILE'."
        exit 1
    fi

    echo -e "${BLUE}[INFO]${NC} Applying declarative sidebar panel layout..."
    JS_SCRIPT=$(cat "$JS_LAYOUT_FILE")
    "$QDBUS_CMD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$JS_SCRIPT"
    echo -e "${GREEN}[SUCCESS]${NC} Left vertical sidebar panel created and configured."
fi

# Register Desktop entry for global shortcuts integration
echo -e "${BLUE}[INFO]${NC} Creating desktop entry for shortcut registration..."
mkdir -p "$DESKTOP_ENTRY_DIR"
cat <<EOF > "$DESKTOP_ENTRY_FILE"
[Desktop Entry]
Type=Application
Name=Toggle Plasma Sidebar
Comment=Toggle KDE Plasma 6 Left Vertical Sidebar Visibility
Exec=$TOGGLE_SCRIPT
Icon=sidebar-show-symbolic
Terminal=false
Categories=Utility;
X-KDE-GlobalAccel-CommandShortcut=true
StartupNotify=false
EOF

# Register Global Shortcuts in KDE Plasma 6
if command -v kwriteconfig6 >/dev/null 2>&1; then
    echo -e "${BLUE}[INFO]${NC} Registering global shortcuts (NitroSense key / Meta+Alt+S)..."

    # Avoid conflict with kaccess screen reader shortcut
    kwriteconfig6 --file kglobalshortcutsrc --group "kaccess" --key "Toggle Screen Reader On and Off" "none,none,Toggle Screen Reader On and Off"

    # Register toggle shortcuts
    kwriteconfig6 --file kglobalshortcutsrc --group "services/toggle-plasma-sidebar.desktop" --key "_k_friendly_name" "Toggle Plasma Sidebar"
    kwriteconfig6 --file kglobalshortcutsrc --group "services/toggle-plasma-sidebar.desktop" --key "_launch" "Launch (1)\tMeta+Alt+S,none,Toggle Plasma Sidebar"

    # Reload KGlobalAccel shortcuts daemon
    if "$QDBUS_CMD" org.kde.KGlobalAccel /KGlobalAccel >/dev/null 2>&1; then
        "$QDBUS_CMD" org.kde.KGlobalAccel /KGlobalAccel reloadConfig >/dev/null 2>&1 || true
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Global shortcuts registered."
fi

echo -e "${GREEN}✅ KDE Plasma 6 Customizable Sidebar setup completed successfully!${NC}"
