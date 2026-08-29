#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run with bash
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# Locate the correct hwmon directory
HWMON_DIR=""
for _ in {1..10}; do
    for dir in /sys/class/hwmon/hwmon*; do
        if [ -f "$dir/name" ] && [ "$(cat "$dir/name" 2>/dev/null)" = "acer_nitro_ec" ]; then
            HWMON_DIR="$dir"
            break 2
        fi
    done
    sleep 0.1
done

if [ -z "$HWMON_DIR" ]; then
    echo "❌ Error: Could not find acer_nitro_ec hwmon interface under /sys/class/hwmon/"
    exit 1
fi

ACTION="${1:-toggle}"

notify() {
    local title="$1"
    local msg="$2"
    local icon="$3"
    if command -v notify-send &>/dev/null && [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ]; then
        notify-send -u normal -t 2500 -i "$icon" "$title" "$msg" 2>/dev/null || true
    fi
}

write_pwm() {
    local val="$1"
    local p1="$HWMON_DIR/pwm1_enable"
    local p2="$HWMON_DIR/pwm2_enable"

    # 1. Direct write if sysfs is writable (after running setup-nitro-permissions.sh)
    if [ -w "$p1" ] && [ -w "$p2" ]; then
        echo "$val" > "$p1"
        echo "$val" > "$p2"
        return 0
    fi

    # 2. Sudo without password if sudoers rule is present
    if sudo -n true 2>/dev/null; then
        sudo sh -c "echo '$val' > '$p1' && echo '$val' > '$p2'"
        return 0
    fi

    # 3. GUI Password prompt via Zenity if running from Desktop
    if [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ] && command -v zenity >/dev/null 2>&1; then
        PASS=$(zenity --password --title="Acer Nitro Fan Control" 2>/dev/null || echo "")
        if [ -n "$PASS" ]; then
            if echo "$PASS" | sudo -S sh -c "echo '$val' > '$p1' && echo '$val' > '$p2'" 2>/dev/null; then
                return 0
            else
                notify "Authentication Error" "Incorrect password entered." "dialog-error"
                zenity --error --title="Authentication Failed" --text="Incorrect password. Fan speed was not changed." 2>/dev/null || true
                exit 1
            fi
        else
            echo "Cancelled by user."
            exit 0
        fi
    fi

    # 4. Fallback to pkexec or sudo in terminal
    if [ -t 0 ]; then
        sudo sh -c "echo '$val' > '$p1' && echo '$val' > '$p2'"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec sh -c "echo '$val' > '$p1' && echo '$val' > '$p2'"
    fi
}

CURRENT_MODE=$(cat "$HWMON_DIR/pwm1_enable" 2>/dev/null || echo "")

case "$ACTION" in
    status)
        if [ "$CURRENT_MODE" = "0" ]; then
            echo "Current Mode: TURBO (Max Speed)"
        elif [ "$CURRENT_MODE" = "1" ]; then
            echo "Current Mode: MANUAL"
        elif [ "$CURRENT_MODE" = "2" ]; then
            echo "Current Mode: AUTO"
        else
            echo "Current Mode: UNKNOWN ($CURRENT_MODE)"
        fi
        exit 0
        ;;
    turbo|max|on)
        echo "➜ Setting Fan Speed to: TURBO (Max Speed)..."
        write_pwm 0
        notify "Acer Nitro Fans" "Fan speed set to TURBO (Max)" "weather-storm"
        ;;
    auto|normal|off)
        echo "➜ Setting Fan Speed to: AUTO..."
        write_pwm 2
        notify "Acer Nitro Fans" "Fan speed set to AUTO" "weather-few-clouds"
        ;;
    toggle|*)
        if [ "$CURRENT_MODE" = "0" ]; then
            echo "➜ Switching to: AUTO..."
            write_pwm 2
            notify "Acer Nitro Fans" "Fan speed switched to AUTO" "weather-few-clouds"
        else
            echo "➜ Switching to: TURBO (Max Speed)..."
            write_pwm 0
            notify "Acer Nitro Fans" "Fan speed switched to TURBO (Max)" "weather-storm"
        fi
        ;;
esac
