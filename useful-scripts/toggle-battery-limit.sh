#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run with bash
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# Check if acer-wmi-battery-dkms is installed
if ! pacman -Q acer-wmi-battery-dkms &>/dev/null && ! yay -Q acer-wmi-battery-dkms &>/dev/null && ! modinfo acer_wmi_battery &>/dev/null; then
    echo "❌ acer-wmi-battery-dkms is not installed."
    echo "Please install it by running: yay -S acer-wmi-battery-dkms"
    exit 1
fi

run_root() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    elif sudo -n true 2>/dev/null; then
        sudo "$@"
    elif [ -t 0 ]; then
        sudo "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec "$@"
    else
        sudo "$@"
    fi
}

notify() {
    local title="$1"
    local msg="$2"
    local icon="$3"
    if command -v notify-send &>/dev/null && [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ]; then
        notify-send -u normal -t 2500 -i "$icon" "$title" "$msg" 2>/dev/null || true
    fi
}

# Path to the module configuration file
CONF="/etc/modprobe.d/acer-wmi-battery.conf"

echo "=========================================="
echo " Acer Battery Charge Limit Toggle"
echo "=========================================="

# Check current state
CURRENT_STATE="100"
if [ -f "$CONF" ] && grep -q "enable_health_mode=1" "$CONF"; then
    CURRENT_STATE="80"
elif [ -f "/sys/bus/wmi/drivers/acer-wmi-battery/health_mode" ]; then
    if [ "$(cat /sys/bus/wmi/drivers/acer-wmi-battery/health_mode 2>/dev/null)" = "1" ]; then
        CURRENT_STATE="80"
    fi
fi

if [ "$CURRENT_STATE" = "80" ]; then
    echo "➜ Current State: 80% Limit ENABLED"
    echo "➜ Changing to: 100% Full Charge..."

    run_root sh -c "echo 'options acer_wmi_battery enable_health_mode=0' > '$CONF' && rmmod acer_wmi_battery 2>/dev/null || true; modprobe acer_wmi_battery 2>/dev/null || true"

    echo "✔ Limit removed. Your battery will now charge to 100%."
    notify "Acer Battery Health" "Charge Limit Disabled (100% Full Charge)" "battery-charging"
else
    echo "➜ Current State: 100% Full Charge"
    echo "➜ Changing to: 80% Limit..."

    run_root sh -c "echo 'options acer_wmi_battery enable_health_mode=1' > '$CONF' && rmmod acer_wmi_battery 2>/dev/null || true; modprobe acer_wmi_battery 2>/dev/null || true"

    echo "✔ Limit applied. Your battery will stop charging at 80%."
    notify "Acer Battery Health" "Charge Limit Enabled (80% Health Mode)" "security-high"
fi