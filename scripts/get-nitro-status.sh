#!/usr/bin/env bash
# ==============================================================================
# Get Acer Nitro Fan, Battery, and System Stats (JSON Output for KDE Plasmoid)
# ==============================================================================

# Locate hwmon directory for acer_nitro_ec
HWMON_DIR=""
for dir in /sys/class/hwmon/hwmon*; do
    if [ -f "$dir/name" ] && [ "$(cat "$dir/name" 2>/dev/null)" = "acer_nitro_ec" ]; then
        HWMON_DIR="$dir"
        break
    fi
done

CPU_FAN=0
GPU_FAN=0
CPU_TEMP=0
GPU_TEMP=0
PWM_MODE="2"
FAN_MODE="auto"
FAN_TURBO=false

if [ -n "$HWMON_DIR" ]; then
    [ -f "$HWMON_DIR/fan1_input" ] && CPU_FAN=$(cat "$HWMON_DIR/fan1_input" 2>/dev/null || echo 0)
    [ -f "$HWMON_DIR/fan2_input" ] && GPU_FAN=$(cat "$HWMON_DIR/fan2_input" 2>/dev/null || echo 0)
    [ -f "$HWMON_DIR/temp1_input" ] && CPU_TEMP=$(($(cat "$HWMON_DIR/temp1_input" 2>/dev/null || echo 0) / 1000))
    [ -f "$HWMON_DIR/temp2_input" ] && GPU_TEMP=$(($(cat "$HWMON_DIR/temp2_input" 2>/dev/null || echo 0) / 1000))
    [ -f "$HWMON_DIR/pwm1_enable" ] && PWM_MODE=$(cat "$HWMON_DIR/pwm1_enable" 2>/dev/null || echo "2")
fi

if [ "$PWM_MODE" = "0" ]; then
    FAN_MODE="turbo"
    FAN_TURBO=true
elif [ "$PWM_MODE" = "1" ]; then
    FAN_MODE="manual"
    FAN_TURBO=false
else
    FAN_MODE="auto"
    FAN_TURBO=false
fi

# Battery Limit check
BAT_LIMIT_ENABLED=false
if [ -f "/sys/bus/wmi/drivers/acer-wmi-battery/health_mode" ]; then
    HEALTH_VAL=$(cat /sys/bus/wmi/drivers/acer-wmi-battery/health_mode 2>/dev/null || echo "0")
    if [ "$HEALTH_VAL" = "1" ]; then
        BAT_LIMIT_ENABLED=true
    fi
elif [ -f "/etc/modprobe.d/acer-wmi-battery.conf" ]; then
    if grep -q "enable_health_mode=1" "/etc/modprobe.d/acer-wmi-battery.conf" 2>/dev/null; then
        BAT_LIMIT_ENABLED=true
    fi
fi

# Battery capacity & status
BAT_CAPACITY=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0)
BAT_STATUS=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")

# RAM Usage (%)
MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 1)
MEM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
RAM_PERCENT=$(( 100 * (MEM_TOTAL - MEM_AVAIL) / MEM_TOTAL ))

# CPU Usage (%) calculation using /proc/stat
CPU_STATE_FILE="/tmp/nitro_cpu_stat.tmp"
CPU_PERCENT=0
if [ -f /proc/stat ]; then
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    CURRENT_TOTAL=$((user + nice + system + idle + iowait + irq + softirq + steal))
    CURRENT_IDLE=$((idle + iowait))

    if [ -f "$CPU_STATE_FILE" ]; then
        read -r PREV_TOTAL PREV_IDLE < "$CPU_STATE_FILE"
        DIFF_TOTAL=$((CURRENT_TOTAL - PREV_TOTAL))
        DIFF_IDLE=$((CURRENT_IDLE - PREV_IDLE))
        if [ "$DIFF_TOTAL" -gt 0 ]; then
            CPU_PERCENT=$(( (1000 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL + 5) / 10 ))
        fi
    fi
    echo "$CURRENT_TOTAL $CURRENT_IDLE" > "$CPU_STATE_FILE"
fi

cat <<EOF
{
  "cpu_fan_rpm": $CPU_FAN,
  "gpu_fan_rpm": $GPU_FAN,
  "cpu_temp": $CPU_TEMP,
  "gpu_temp": $GPU_TEMP,
  "cpu_percent": $CPU_PERCENT,
  "ram_percent": $RAM_PERCENT,
  "fan_mode": "$FAN_MODE",
  "fan_turbo": $FAN_TURBO,
  "battery_limit_enabled": $BAT_LIMIT_ENABLED,
  "battery_percent": $BAT_CAPACITY,
  "battery_status": "$BAT_STATUS"
}
EOF
