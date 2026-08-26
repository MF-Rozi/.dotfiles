#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run with bash
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# Check if acer-nitro-ec-dkms is installed or module is available
if ! pacman -Q acer-nitro-ec-dkms &>/dev/null && ! yay -Q acer-nitro-ec-dkms &>/dev/null && ! modinfo acer_nitro_ec &>/dev/null; then
    echo "❌ acer-nitro-ec-dkms is not installed."
    echo "Please install it by running: yay -S acer-nitro-ec-dkms"
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

# Function to automatically patch and rebuild DKMS module for AN515-55 if missing
fix_unsupported_model() {
    local dkms_c_file="/usr/src/acer-nitro-ec-1.0.0/acer-nitro-ec.c"
    local model_name
    model_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")

    if [[ "$model_name" =~ "AN515-55" ]] && [ -f "$dkms_c_file" ]; then
        if ! grep -q "AN515-55" "$dkms_c_file"; then
            echo "➜ Detected $model_name (missing in default acer-nitro-ec DMI table)."
            echo "➜ Patching $dkms_c_file and rebuilding DKMS module..."
            sudo sed -i '/AN515-54/a \\t\t strstr(model, "AN515-55") ||' "$dkms_c_file"
            sudo dkms build acer-nitro-ec/1.0.0 --force
            sudo dkms install acer-nitro-ec/1.0.0 --force
            return 0
        fi
    fi
    return 1
}

# Ensure kernel module is loaded
if ! lsmod | grep -q "^acer_nitro_ec"; then
    echo "➜ Loading kernel module acer_nitro_ec..."
    if ! sudo modprobe acer_nitro_ec 2>/dev/null; then
        echo "⚠️  Initial modprobe failed. Checking if kernel module needs patching for your laptop model..."
        if fix_unsupported_model && sudo modprobe acer_nitro_ec; then
            echo "✔ Kernel module successfully patched and loaded!"
        else
            echo "❌ Error: Failed to load acer_nitro_ec kernel module."
            echo "Run 'sudo dmesg | grep acer-nitro-ec' or check DKMS status with 'dkms status'."
            exit 1
        fi
    fi
fi

# Locate the correct hwmon directory (with a brief retry loop)
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

print_status() {
    echo "------------------------------------------"
    # CPU & GPU Fan Speed
    if [ -f "$HWMON_DIR/fan1_input" ]; then
        echo "CPU Fan Speed: $(cat "$HWMON_DIR/fan1_input") RPM"
    fi
    if [ -f "$HWMON_DIR/fan2_input" ]; then
        echo "GPU Fan Speed: $(cat "$HWMON_DIR/fan2_input") RPM"
    fi

    # Temperatures
    if [ -f "$HWMON_DIR/temp1_input" ]; then
        local cpu_temp=$(($(cat "$HWMON_DIR/temp1_input") / 1000))
        echo "CPU Temp:      ${cpu_temp}°C"
    fi
    if [ -f "$HWMON_DIR/temp2_input" ]; then
        local gpu_temp=$(($(cat "$HWMON_DIR/temp2_input") / 1000))
        echo "GPU Temp:      ${gpu_temp}°C"
    fi
    if [ -f "$HWMON_DIR/temp3_input" ]; then
        local sys_temp=$(($(cat "$HWMON_DIR/temp3_input") / 1000))
        echo "System Temp:   ${sys_temp}°C"
    fi
    echo "------------------------------------------"
}

notify() {
    local title="$1"
    local msg="$2"
    local icon="$3"
    if command -v notify-send &>/dev/null && [ -n "${DISPLAY:-${WAYLAND_DISPLAY:-}}" ]; then
        notify-send -u normal -t 2500 -i "$icon" "$title" "$msg" 2>/dev/null || true
    fi
}

echo "=========================================="
echo " Acer Nitro Fan Turbo Toggle"
echo "=========================================="

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
        print_status
        exit 0
        ;;
    turbo|max|on)
        echo "➜ Setting Fan Speed to: TURBO (Max Speed)..."
        run_root sh -c "echo 0 > '$HWMON_DIR/pwm1_enable' && echo 0 > '$HWMON_DIR/pwm2_enable'"
        echo "✔ Fan speed set to TURBO."
        notify "Acer Nitro Fans" "Fan speed set to TURBO (Max)" "weather-storm"
        ;;
    auto|normal|off)
        echo "➜ Setting Fan Speed to: AUTO..."
        run_root sh -c "echo 2 > '$HWMON_DIR/pwm1_enable' && echo 2 > '$HWMON_DIR/pwm2_enable'"
        echo "✔ Fan speed set to AUTO."
        notify "Acer Nitro Fans" "Fan speed set to AUTO" "weather-few-clouds"
        ;;
    toggle|*)
        if [ "$CURRENT_MODE" = "0" ]; then
            echo "➜ Current State: TURBO (Max Speed)"
            echo "➜ Changing to: AUTO..."
            run_root sh -c "echo 2 > '$HWMON_DIR/pwm1_enable' && echo 2 > '$HWMON_DIR/pwm2_enable'"
            echo "✔ Fan speed set to AUTO."
            notify "Acer Nitro Fans" "Fan speed switched to AUTO" "weather-few-clouds"
        else
            echo "➜ Current State: AUTO/MANUAL"
            echo "➜ Changing to: TURBO (Max Speed)..."
            run_root sh -c "echo 0 > '$HWMON_DIR/pwm1_enable' && echo 0 > '$HWMON_DIR/pwm2_enable'"
            echo "✔ Fan speed set to TURBO (Max Speed)."
            notify "Acer Nitro Fans" "Fan speed switched to TURBO (Max)" "weather-storm"
        fi
        ;;
esac

print_status
