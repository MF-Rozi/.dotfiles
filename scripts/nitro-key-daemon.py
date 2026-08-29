#!/usr/bin/env python3
import glob
import os
import select
import struct
import subprocess
import sys
import time

# Linux input_event format for 64-bit:
# timeval (16 bytes), __u16 type, __u16 code, __s32 value = 24 bytes
EVENT_FORMAT = "qqHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)

# Keycode 425 is KEY_PRESENTATION (Acer NitroSense Key)
TARGET_KEYCODES = {425, 148, 156, 128}

TOGGLE_SCRIPT = os.path.expanduser("~/dotfiles/scripts/toggle-plasma-sidebar.sh")

def run_daemon():
    last_trigger = 0

    while True:
        open_fds = {}
        for dev_path in sorted(glob.glob("/dev/input/event*")):
            try:
                fd = open(dev_path, "rb", buffering=0)
                open_fds[fd] = dev_path
            except Exception:
                pass

        if not open_fds:
            time.sleep(2)
            continue

        try:
            while True:
                readable, _, _ = select.select(list(open_fds.keys()), [], [], 2.0)
                for fd in readable:
                    try:
                        raw = fd.read(EVENT_SIZE)
                        if len(raw) == EVENT_SIZE:
                            _, _, ev_type, ev_code, ev_value = struct.unpack(EVENT_FORMAT, raw)
                            # ev_type == 1 (EV_KEY), ev_value == 1 (KEY_DOWN)
                            if ev_type == 1 and ev_value == 1 and ev_code in TARGET_KEYCODES:
                                now = time.time()
                                if now - last_trigger > 0.35:
                                    last_trigger = now
                                    subprocess.Popen(["bash", TOGGLE_SCRIPT], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    except Exception:
                        pass
        except Exception:
            for fd in open_fds:
                try:
                    fd.close()
                except Exception:
                    pass
            time.sleep(1)

if __name__ == "__main__":
    run_daemon()
