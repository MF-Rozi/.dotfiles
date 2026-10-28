#!/usr/bin/env python3
import glob
import os
import select
import struct
import sys
import time

# Linux input_event struct format for 64-bit:
# timeval (16 bytes), __u16 type, __u16 code, __s32 value = 24 bytes
EVENT_FORMAT = "qqHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)

# Map common keycodes to human-readable names
KEY_NAMES = {
    148: "KEY_PROG1 (XF86Launch1)",
    149: "KEY_PROG2 (XF86Launch2)",
    156: "KEY_BOOKMARKS (Launch 1 / NitroSense)",
    128: "KEY_CONFIG (XF86LaunchA)",
    192: "KEY_F24",
    193: "KEY_F23",
    194: "KEY_F22",
    202: "KEY_PROG3",
    203: "KEY_PROG4",
    240: "KEY_UNKNOWN_ACPI",
}

print("==========================================================")
print(" 🔍 Acer Nitro Key Sniffer (Listening for 12 seconds)")
print("==========================================================")
print("👉 PLEASE PRESS YOUR PHYSICAL NITROSENSE KEY NOW...")
print("==========================================================")
sys.stdout.flush()

open_fds = {}
for dev_path in sorted(glob.glob("/dev/input/event*")):
    try:
        fd = open(dev_path, "rb", buffering=0)
        open_fds[fd] = dev_path
    except Exception:
        pass

if not open_fds:
    print("❌ Error: Could not open /dev/input/event* devices. Please run with sudo.")
    sys.exit(1)

start_time = time.time()
detected = False

while time.time() - start_time < 12:
    readable, _, _ = select.select(list(open_fds.keys()), [], [], 0.5)
    for fd in readable:
        try:
            raw = fd.read(EVENT_SIZE)
            if len(raw) == EVENT_SIZE:
                _, _, ev_type, ev_code, ev_value = struct.unpack(EVENT_FORMAT, raw)
                # ev_type == 1 (EV_KEY), ev_value == 1 (KEY_DOWN)
                if ev_type == 1 and ev_value == 1:
                    dev = open_fds[fd]
                    name = KEY_NAMES.get(ev_code, f"Code {ev_code}")
                    print(f"\n🎉 KEY PRESS DETECTED!")
                    print(f"   • Device:  {dev}")
                    print(f"   • Keycode: {ev_code}")
                    print(f"   • Symbol:  {name}")
                    sys.stdout.flush()
                    detected = True
        except Exception:
            pass

for fd in open_fds:
    fd.close()

if not detected:
    print("\n⌛ Timeout: No key press detected in 12 seconds.")
else:
    print("\n✅ Key sniffing complete.")
