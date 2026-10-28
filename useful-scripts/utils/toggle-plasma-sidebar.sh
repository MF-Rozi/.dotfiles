#!/usr/bin/env bash
# ==============================================================================
# Fast Toggle for Sliding Glass Dashboard Drawer
# ==============================================================================

echo "$(date +'%Y-%m-%d %H:%M:%S.%3N'): toggle called" >> /tmp/nitro_toggle_debug.log

TOGGLE_FILE="/tmp/nitro_drawer_toggle"
LOCK_FILE="/tmp/nitro_drawer_toggle.lock"
QML_FILE="$HOME/dotfiles/sidebar-drawer/main.qml"

# Prevent duplicate rapid trigger events (e.g. key-down + key-up bounce within 350ms)
if [ -f "$LOCK_FILE" ]; then
    LAST=$(cat "$LOCK_FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s%3N)
    DIFF=$((NOW - LAST))
    if [ "$DIFF" -lt 350 ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S.%3N'): throttled (diff $DIFF ms)" >> /tmp/nitro_toggle_debug.log
        exit 0
    fi
fi
date +%s%3N > "$LOCK_FILE"

if ! pgrep -f "sidebar-drawer/main.qml" >/dev/null 2>&1; then
    echo "$(date +'%Y-%m-%d %H:%M:%S.%3N'): starting new qml process" >> /tmp/nitro_toggle_debug.log
    nohup env QT_QPA_PLATFORM=xcb qml6 "$QML_FILE" >/dev/null 2>&1 &
else
    echo "$(date +'%Y-%m-%d %H:%M:%S.%3N'): sending IPC toggle signal" >> /tmp/nitro_toggle_debug.log
    date +%s%N > "$TOGGLE_FILE"
fi
