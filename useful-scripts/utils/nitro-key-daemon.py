#!/usr/bin/env python3
import glob
import os
import select
import struct
import subprocess
import time

# Linux input_event format for 64-bit:
# timeval (16 bytes), __u16 type, __u16 code, __s32 value = 24 bytes
EVENT_FORMAT = "qqHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)

# Keycode 425 is KEY_PRESENTATION (Acer NitroSense Key)
TARGET_KEYCODES = {425, 148, 156, 128}

TOGGLE_SCRIPT = os.path.expanduser("~/dotfiles/useful-scripts/utils/toggle-plasma-sidebar.sh")


def scan_devices():
    open_fds = {}
    for dev_path in sorted(glob.glob("/dev/input/event*")):
        try:
            fd = open(dev_path, "rb", buffering=0)
            open_fds[fd] = dev_path
        except Exception:
            pass
    return open_fds


def run_daemon():
    last_trigger = 0

    while True:
        open_fds = scan_devices()

        if not open_fds:
            time.sleep(2)
            continue

        while True:
            fds = list(open_fds.keys())

            # All devices are gone -> rescan (handles full hotplug rotations)
            if not fds:
                break

            readable, _, _ = select.select(fds, [], [], 2.0)
            for fd in readable:
                try:
                    raw = fd.read(EVENT_SIZE)
                except Exception:
                    # Device went away (ENODEV etc.): close and stop watching
                    open_fds.pop(fd, None)
                    try:
                        fd.close()
                    except Exception:
                        pass
                    continue

                if raw == b"":
                    # EOF: device disconnected. Without closing the fd, select()
                    # marks it readable on every loop iteration -> 100% CPU spin.
                    open_fds.pop(fd, None)
                    fd.close()
                    continue

                if len(raw) == EVENT_SIZE:
                    try:
                        _, _, ev_type, ev_code, ev_value = struct.unpack(EVENT_FORMAT, raw)
                        # ev_type == 1 (EV_KEY), ev_value == 1 (KEY_DOWN)
                        if ev_type == 1 and ev_value == 1 and ev_code in TARGET_KEYCODES:
                            now = time.time()
                            if now - last_trigger > 0.35:
                                last_trigger = now
                                subprocess.Popen(
                                    ["bash", TOGGLE_SCRIPT],
                                    stdout=subprocess.DEVNULL,
                                    stderr=subprocess.DEVNULL,
                                )
                    except Exception:
                        pass

            # Pick up newly attached event devices without leaking fds for
            # the existing ones (compare paths, then open only the new ones)
            existing_paths = set(open_fds.values())
            for dev_path in sorted(glob.glob("/dev/input/event*")):
                if dev_path not in existing_paths:
                    try:
                        fd = open(dev_path, "rb", buffering=0)
                        open_fds[fd] = dev_path
                    except Exception:
                        pass


if __name__ == "__main__":
    run_daemon()
