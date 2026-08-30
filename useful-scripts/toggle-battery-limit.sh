#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run with bash
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

SYSFS_HEALTH="/sys/bus/wmi/drivers/acer-wmi-battery/health_mode"
CONF="/etc/modprobe.d/acer-wmi-battery.conf"

notify() {
    local title="$1"
    local msg="$2"
    local icon="$3"
    if command -v notify-send &>/dev/null && [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ]; then
        notify-send -u normal -t 2500 -i "$icon" "$title" "$msg" 2>/dev/null || true
    fi
}

write_health() {
    local val="$1" # 1 for 80% limit, 0 for 100% full

    # 1. Direct sysfs write if writable
    if [ -w "$SYSFS_HEALTH" ]; then
        echo "$val" > "$SYSFS_HEALTH"
        return 0
    fi

    # 2. Sudo without password if sudoers rule is present
    if sudo -n true 2>/dev/null; then
        sudo sh -c "echo '$val' > '$SYSFS_HEALTH' 2>/dev/null || true; echo 'options acer_wmi_battery enable_health_mode=$val' > '$CONF'"
        return 0
    fi

    # 3. GUI Password prompt via Zenity if running from Desktop
    if [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ] && command -v zenity >/dev/null 2>&1; then
        PASS=$(zenity --password --title="Acer Battery Health Control" 2>/dev/null || echo "")
        if [ -n "$PASS" ]; then
            if echo "$PASS" | sudo -S sh -c "echo '$val' > '$SYSFS_HEALTH' 2>/dev/null || true; echo 'options acer_wmi_battery enable_health_mode=$val' > '$CONF'" 2>/dev/null; then
                return 0
            else
                notify "Authentication Error" "Incorrect password entered." "dialog-error"
                zenity --error --title="Authentication Failed" --text="Incorrect password. Battery limit was not changed." 2>/dev/null || true
                exit 1
            fi
        else
            echo "Cancelled by user."
            exit 0
        fi
    fi

    # 4. Fallback to pkexec or sudo in terminal
    if [ -t 0 ]; then
        sudo sh -c "echo '$val' > '$SYSFS_HEALTH' 2>/dev/null || true; echo 'options acer_wmi_battery enable_health_mode=$val' > '$CONF'"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec sh -c "echo '$val' > '$SYSFS_HEALTH' 2>/dev/null || true; echo 'options acer_wmi_battery enable_health_mode=$val' > '$CONF'"
    fi
}

echo "=========================================="
echo " Acer Battery Charge Limit Toggle"
echo "=========================================="

# Check current state
CURRENT_STATE="100"
if [ -f "$SYSFS_HEALTH" ] && [ "$(cat "$SYSFS_HEALTH" 2>/dev/null)" = "1" ]; then
    CURRENT_STATE="80"
elif [ -f "$CONF" ] && grep -q "enable_health_mode=1" "$CONF"; then
    CURRENT_STATE="80"
fi

if [ "$CURRENT_STATE" = "80" ]; then
    echo "➜ Current State: 80% Limit ENABLED"
    echo "➜ Changing to: 100% Full Charge..."
    write_health 0
    echo "✔ Limit removed. Your battery will now charge to 100%."
    notify "Acer Battery Health" "Charge Limit Disabled (100% Full Charge)" "battery-charging"
else
    echo "➜ Current State: 100% Full Charge"
    echo "➜ Changing to: 80% Limit..."
    write_health 1
    echo "✔ Limit applied. Your battery will stop charging at 80%."
    notify "Acer Battery Health" "Charge Limit Enabled (80% Health Mode)" "security-high"
fi