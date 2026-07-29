#!/usr/bin/env bash

# check yay -S acer-wmi-battery-dkms installed first

if ! yay -Q acer-wmi-battery-dkms &> /dev/null; then
    echo "acer-wmi-battery-dkms is not installed."
    echo "Please install it by running: yay -S acer-wmi-battery-dkms"
    exit 1
fi


# Path to the module configuration file
CONF="/etc/modprobe.d/acer-wmi-battery.conf"

echo "=========================================="
echo " Acer Battery Charge Limit Toggle"
echo "=========================================="

if grep -q "enable_health_mode=1" "$CONF"; then
    echo "➜ Current State: 80% Limit ENABLED"
    echo "➜ Changing to: 100% Full Charge..."
    
    # Write the new rule for 100%
    echo "options acer_wmi_battery enable_health_mode=0" | sudo tee "$CONF" > /dev/null
    
    # Reload the kernel module to apply instantly
    sudo rmmod acer_wmi_battery && sudo modprobe acer_wmi_battery
    
    echo "✔ Limit removed. Your battery will now charge to 100%."
else
    echo "➜ Current State: 100% Full Charge"
    echo "➜ Changing to: 80% Limit..."
    
    # Write the new rule for 80%
    echo "options acer_wmi_battery enable_health_mode=1" | sudo tee "$CONF" > /dev/null
    
    # Reload the kernel module to apply instantly
    sudo rmmod acer_wmi_battery && sudo modprobe acer_wmi_battery
    
    echo "✔ Limit applied. Your battery will stop charging at 80%."
fi