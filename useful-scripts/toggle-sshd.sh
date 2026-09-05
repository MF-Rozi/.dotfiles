#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run with bash
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

CONF_SRC="/home/mfrozi/dotfiles/config/ssh/10-post-quantum-lan.conf"
CONF_DEST="/etc/ssh/sshd_config.d/10-post-quantum-lan.conf"

notify() {
    local title="$1"
    local msg="$2"
    local icon="$3"
    if command -v notify-send &>/dev/null && [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ]; then
        notify-send -u normal -t 4000 -i "$icon" "$title" "$msg" 2>/dev/null || true
    fi
}

run_as_root() {
    local cmd="$1"

    # 1. Sudo without password if sudoers rule is present
    if sudo -n true 2>/dev/null; then
        sudo sh -c "$cmd"
        return 0
    fi

    # 2. GUI Password prompt via Zenity if running from Desktop
    if [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ] && command -v zenity >/dev/null 2>&1; then
        PASS=$(zenity --password --title="SSH Server Control Authentication" 2>/dev/null || echo "")
        if [ -n "$PASS" ]; then
            if echo "$PASS" | sudo -S sh -c "$cmd" 2>/dev/null; then
                return 0
            else
                notify "Authentication Error" "Incorrect password entered." "dialog-error"
                zenity --error --title="Authentication Failed" --text="Incorrect password. SSH status was not changed." 2>/dev/null || true
                exit 1
            fi
        else
            echo "Cancelled by user."
            exit 0
        fi
    fi

    # 3. Fallback to pkexec or interactive sudo in terminal
    if [ -t 0 ]; then
        sudo sh -c "$cmd"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec sh -c "$cmd"
    else
        echo "Error: Root privilege required to manage sshd service." >&2
        exit 1
    fi
}

get_lan_ip() {
    local ip
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk "{print \$7; exit}")
    if [ -z "$ip" ]; then
        ip=$(ip -4 addr show scope global | awk "/inet / {print \$2}" | cut -d/ -f1 | head -n 1)
    fi
    echo "${ip:-127.0.0.1}"
}

echo "=========================================="
echo " SSH Server (sshd) Toggle"
echo "=========================================="

IS_ACTIVE=$(systemctl is-active sshd.service 2>/dev/null || echo "inactive")

if [ "$IS_ACTIVE" = "active" ]; then
    echo "➜ Current State: SSH Server is RUNNING"
    echo "➜ Stopping sshd service..."
    run_as_root "systemctl stop sshd.service"
    echo "✔ SSH Server stopped."
    notify "SSH Server Disabled" "Remote SSH daemon has been stopped." "network-offline"
else
    echo "➜ Current State: SSH Server is STOPPED"
    echo "➜ Starting sshd service with Post-Quantum hardening..."
    
    SETUP_CMDS="
        ssh-keygen -A
        if [ -f '$CONF_SRC' ]; then
            mkdir -p /etc/ssh/sshd_config.d
            cp '$CONF_SRC' '$CONF_DEST'
            chmod 644 '$CONF_DEST'
        fi
        systemctl start sshd.service
    "
    run_as_root "$SETUP_CMDS"
    
    LAN_IP=$(get_lan_ip)
    echo "✔ SSH Server is now ACTIVE (LAN only)."
    echo ""
    echo "------------------------------------------"
    echo " Connect from your remote device:"
    echo "   ssh -i ~/.ssh/id_ed25519_remotecode mfrozi@$LAN_IP"
    echo "------------------------------------------"
    notify "SSH Server Active (LAN)" "Listening on $LAN_IP:22\nPost-quantum encryption enabled" "network-wired"
fi
