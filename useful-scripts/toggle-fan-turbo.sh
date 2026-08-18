#!/usr/bin/env bash

# Check if acer-nitro-ec-dkms is installed
if ! yay -Q acer-nitro-ec-dkms &> /dev/null; then
    echo "acer-nitro-ec-dkms is not installed."
    echo "Please install it by running: yay -S acer-nitro-ec-dkms"
    exit 1
fi

# Ensure module is loaded
if ! lsmod | grep -q acer_nitro_ec; then
    echo "➜ Loading kernel module acer_nitro_ec..."
    if ! sudo modprobe acer_nitro_ec; then
        echo "❌ Error: Failed to load acer_nitro_ec kernel module."
        exit 1
    fi
fi

# Locate the correct hwmon directory
HWMON_DIR=""
for dir in /sys/class/hwmon/hwmon*; do
    if [ -f "$dir/name" ] && [ "$(cat "$dir/name")" = "acer_nitro_ec" ]; then
        HWMON_DIR="$dir"
        break
    fi
done

if [ -z "$HWMON_DIR" ]; then
    echo "❌ Error: Could not find acer_nitro_ec hwmon interface under /sys/class/hwmon/"
    exit 1
fi

echo "=========================================="
echo " Acer Nitro Fan Turbo Toggle"
echo "=========================================="

# Read current mode of CPU fan (pwm1_enable)
# 0 = Turbo, 1 = Manual, 2 = Auto
CURRENT_MODE=$(cat "$HWMON_DIR/pwm1_enable" 2>/dev/null)

if [ "$CURRENT_MODE" = "0" ]; then
    echo "➜ Current State: TURBO (Max Speed)"
    echo "➜ Changing to: AUTO..."
    
    echo 2 | sudo tee "$HWMON_DIR/pwm1_enable" > /dev/null
    echo 2 | sudo tee "$HWMON_DIR/pwm2_enable" > /dev/null
    
    echo "✔ Fan speed set to AUTO."
else
    echo "➜ Current State: AUTO/MANUAL"
    echo "➜ Changing to: TURBO (Max Speed)..."
    
    echo 0 | sudo tee "$HWMON_DIR/pwm1_enable" > /dev/null
    echo 0 | sudo tee "$HWMON_DIR/pwm2_enable" > /dev/null
    
    echo "✔ Fan speed set to TURBO (Max Speed)."
fi

# Display current speeds
if [ -f "$HWMON_DIR/fan1_input" ]; then
    echo "CPU Fan: $(cat "$HWMON_DIR/fan1_input") RPM"
fi
if [ -f "$HWMON_DIR/fan2_input" ]; then
    echo "GPU Fan: $(cat "$HWMON_DIR/fan2_input") RPM"
fi
