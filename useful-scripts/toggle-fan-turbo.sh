#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run with bash
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

if [ "${1:-}" = "--check-elevation" ]; then
    exit 0
fi

# Auto-elevate using sudo if passwordless sudo is available (configured in /etc/sudoers)
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if sudo -n "$0" --check-elevation 2>/dev/null; then
        exec sudo "$0" "$@"
    fi
fi

# Locate the correct hwmon directory for acer_nitro_ec
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
    echo "❌ Error: Could not find acer_nitro_ec hwmon interface under /sys/class/hwmon/" >&2
    exit 1
fi

notify() {
    local title="$1"
    local msg="$2"
    local icon="$3"
    local target_user="${SUDO_USER:-$USER}"

    if [ -n "$target_user" ] && [ "$target_user" != "root" ] && command -v notify-send &>/dev/null; then
        local user_id
        user_id=$(id -u "$target_user" 2>/dev/null || echo "1000")
        sudo -u "$target_user" \
            DISPLAY="${DISPLAY:-:0}" \
            WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$user_id/bus" \
            notify-send -u normal -t 2500 -i "$icon" "$title" "$msg" 2>/dev/null || true
    elif command -v notify-send &>/dev/null && [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ]; then
        notify-send -u normal -t 2500 -i "$icon" "$title" "$msg" 2>/dev/null || true
    fi
}

write_pwm() {
    local val="$1"
    local p1="$HWMON_DIR/pwm1_enable"
    local p2="$HWMON_DIR/pwm2_enable"

    # 1. Direct write if running as root or files are writable
    if [ -w "$p1" ] && [ -w "$p2" ]; then
        echo "$val" > "$p1"
        echo "$val" > "$p2"
        return 0
    fi

    # 2. Sudo without password
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

    # 4. Fallback to interactive sudo in terminal or pkexec
    if [ -t 0 ]; then
        sudo sh -c "echo '$val' > '$p1' && echo '$val' > '$p2'"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec sh -c "echo '$val' > '$p1' && echo '$val' > '$p2'"
    fi
}

get_coolboost_val() {
    if ! command -v ec_probe >/dev/null 2>&1; then
        echo "unavailable"
        return
    fi

    local raw
    raw=$(ec_probe read 0x10 2>/dev/null || echo "")

    if echo "$raw" | grep -qi "0x01\|1 ("; then
        echo "1"
    elif echo "$raw" | grep -qi "0x00\|0 ("; then
        echo "0"
    else
        echo "unknown"
    fi
}

set_coolboost() {
    local val="$1" # 1 for ON, 0 for OFF

    if ! command -v ec_probe >/dev/null 2>&1; then
        echo "❌ Error: ec_probe is not installed (nbfc-linux required)." >&2
        notify "CoolBoost Error" "ec_probe command not found." "dialog-error"
        return 1
    fi

    local hex_val
    if [ "$val" = "1" ]; then
        hex_val="0x01"
    else
        hex_val="0x00"
    fi

    local success=false
    if ec_probe write 0x10 "$hex_val" >/dev/null 2>&1; then
        success=true
    fi

    if [ "$success" = true ]; then
        if [ "$val" = "1" ]; then
            echo "✔ CoolBoost™ is now ENABLED."
            notify "Acer Nitro CoolBoost" "CoolBoost™ ENABLED (+10% auto fan boost)" "weather-storm"
        else
            echo "✔ CoolBoost™ is now DISABLED."
            notify "Acer Nitro CoolBoost" "CoolBoost™ DISABLED (Standard auto curve)" "weather-few-clouds"
        fi
        return 0
    else
        echo "❌ Error: Root privilege required to write to EC register 0x10." >&2
        notify "Authentication Error" "Failed to set CoolBoost (insufficient permissions)." "dialog-error"
        return 1
    fi
}

show_status() {
    local current_mode
    current_mode=$(cat "$HWMON_DIR/pwm1_enable" 2>/dev/null || echo "")

    local cpu_rpm gpu_rpm cpu_temp gpu_temp
    cpu_rpm=$(cat "$HWMON_DIR/fan1_input" 2>/dev/null || echo "0")
    gpu_rpm=$(cat "$HWMON_DIR/fan2_input" 2>/dev/null || echo "0")
    cpu_temp=$(cat "$HWMON_DIR/temp1_input" 2>/dev/null || echo "0")
    gpu_temp=$(cat "$HWMON_DIR/temp2_input" 2>/dev/null || echo "0")

    local cb_val
    cb_val=$(get_coolboost_val)

    echo "=========================================="
    echo " Acer Nitro Fan & Thermal Status"
    echo "=========================================="
    if [ "$current_mode" = "0" ]; then
        echo " Fan Mode          : TURBO (Max Speed)"
    elif [ "$current_mode" = "1" ]; then
        echo " Fan Mode          : MANUAL"
    elif [ "$current_mode" = "2" ]; then
        echo " Fan Mode          : AUTO"
    else
        echo " Fan Mode          : UNKNOWN ($current_mode)"
    fi

    if [ "$cb_val" = "1" ]; then
        echo " CoolBoost™        : ENABLED (Active)"
    elif [ "$cb_val" = "0" ]; then
        echo " CoolBoost™        : DISABLED"
    else
        echo " CoolBoost™        : $cb_val"
    fi

    echo " CPU Fan Speed     : ${cpu_rpm} RPM"
    echo " GPU Fan Speed     : ${gpu_rpm} RPM"
    echo " CPU Temperature   : $(( cpu_temp / 1000 ))°C"
    echo " GPU Temperature   : $(( gpu_temp / 1000 ))°C"
    echo "=========================================="
}

ACTION="${1:-toggle}"
SUB_ACTION="${2:-toggle}"

case "$ACTION" in
    status)
        show_status
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
    coolboost|cb)
        case "$SUB_ACTION" in
            on|enable|1)
                set_coolboost 1
                ;;
            off|disable|0)
                set_coolboost 0
                ;;
            toggle|*)
                current_cb=$(get_coolboost_val)
                if [ "$current_cb" = "1" ]; then
                    set_coolboost 0
                else
                    set_coolboost 1
                fi
                ;;
        esac
        ;;
    toggle)
        CURRENT_MODE=$(cat "$HWMON_DIR/pwm1_enable" 2>/dev/null || echo "")
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
    *)
        echo "Usage: $0 {toggle|turbo|auto|coolboost [on|off|toggle]|status}"
        exit 1
        ;;
esac
