#!/usr/bin/env bash
# ==============================================================================
# Setup Passwordless Permissions for Acer Nitro Hardware Controls & Key Daemon
# ==============================================================================

set -e

CURRENT_USER="${SUDO_USER:-$USER}"

if [ "$EUID" -ne 0 ]; then
    echo "➜ Running with sudo elevation..."
    exec sudo bash "$0" "$@"
fi

echo "➜ [1/4] Creating systemd-tmpfiles configuration for sysfs nodes..."
cat <<EOF > /etc/tmpfiles.d/acer-nitro.conf
z /sys/class/hwmon/hwmon*/pwm*_enable 0666 root root -
z /sys/bus/wmi/drivers/acer-wmi-battery/health_mode 0666 root root -
EOF

echo "➜ [2/4] Creating udev rules for automatic sysfs and keyboard event permissions..."
cat <<EOF > /etc/udev/rules.d/99-acer-nitro.rules
# Hardware sysfs control permissions
SUBSYSTEM=="hwmon", ATTR{name}=="acer_nitro_ec", RUN+="/bin/chmod a+w /sys/class/hwmon/%k/pwm1_enable /sys/class/hwmon/%k/pwm2_enable"
SUBSYSTEM=="wmi", ATTR{health_mode}=="*", RUN+="/bin/chmod a+w /sys/bus/wmi/drivers/acer-wmi-battery/health_mode"

# Allow user access to keyboard input events for NitroSense key daemon
KERNEL=="event*", SUBSYSTEM=="input", TAG+="uaccess", MODE="0660", GROUP="input"
EOF

# Add current user to input group if not already a member
if ! id -nG "$CURRENT_USER" | grep -qw "input"; then
    echo "➜ Adding user $CURRENT_USER to 'input' group..."
    usermod -aG input "$CURRENT_USER"
fi

echo "➜ [3/4] Creating sudoers rule for hardware toggle scripts..."
cat <<EOF > /etc/sudoers.d/acer-nitro-control
%wheel ALL=(ALL) NOPASSWD: /home/mfrozi/dotfiles/useful-scripts/toggle-fan-turbo.sh, /home/mfrozi/dotfiles/useful-scripts/toggle-battery-limit.sh
EOF
chmod 0440 /etc/sudoers.d/acer-nitro-control

echo "➜ [4/4] Applying permissions to active devices..."
chmod a+w /sys/class/hwmon/hwmon*/pwm*_enable 2>/dev/null || true
chmod a+w /sys/bus/wmi/drivers/acer-wmi-battery/health_mode 2>/dev/null || true
chmod a+r /dev/input/event* 2>/dev/null || true

echo "✅ All Nitro hardware and key permissions configured successfully!"
