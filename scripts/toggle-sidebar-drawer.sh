#!/usr/bin/env bash
# ==============================================================================
# Toggle Sliding Glass Dashboard Drawer
# ==============================================================================

DOTFILES_DIR="$HOME/dotfiles"
QML_FILE="$DOTFILES_DIR/sidebar-drawer/main.qml"
TOGGLE_FILE="/tmp/nitro_drawer_toggle"

# Check if QML drawer is already running
if pgrep -f "qml6.*sidebar-drawer/main.qml" >/dev/null 2>&1; then
    # Trigger smooth slide toggle in running process
    date +%s%N > "$TOGGLE_FILE"
else
    # Start drawer process
    date +%s%N > "$TOGGLE_FILE"
    nohup qml6 "$QML_FILE" >/dev/null 2>&1 &
fi
