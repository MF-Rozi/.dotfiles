# /// script
# dependencies = [
#   "requests",
# ]
# ///

import os
import re
import time
import requests

# ==================== CONFIGURATION ====================
# Your Discord Webhook URL
DISCORD_WEBHOOK_URL = "INSERT YOUR DISCORD WEBHOOK URL HERE"

# Path to your Minecraft instance log file
LOG_PATH = os.path.expanduser(
    "INSERT THE PATH TO YOUR Minecraft LOG FILE HERE"
)
# =======================================================

# Regex to match game chat from the logs
CHAT_REGEX = re.compile(r"\[\d{2}:\d{2}:\d{2}\] \[Render thread/INFO\]: \[System\] \[CHAT\] (.*)")

# Regex pattern to find and remove "[username head]" tags dynamically
HEAD_REMOVAL_REGEX = re.compile(r"\[\S+\s+head\]")

def send_to_discord(message):
    """Sends a clean text string to the configured Discord webhook."""
    payload = {"content": message}
    try:
        response = requests.post(DISCORD_WEBHOOK_URL, json=payload)
        if response.status_code != 204:
            print(f"[Error] Discord returned status code: {response.status_code}")
    except Exception as e:
        print(f"[Error] Failed to connect to Discord: {e}")

def tail_log():
    """Watches the latest.log file for updates in real-time."""
    print(f"[*] Starting log monitor on: {LOG_PATH}")
    print("[*] Forwarding all chat messages...")

    # Wait for the file to be created if the game isn't running yet
    while not os.path.exists(LOG_PATH):
        time.sleep(1)

    with open(LOG_PATH, "r", encoding="utf-8", errors="ignore") as f:
        # Move the pointer to the end of the file so it only catches NEW messages
        f.seek(0, os.SEEK_END)
        
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.1)  # Sleep briefly to avoid high CPU usage
                continue
            
            clean_line = line.strip()
            match = CHAT_REGEX.match(clean_line)
            
            if match:
                chat_content = match.group(1).strip()

                # Strip out any "[username head]" pattern
                clean_chat = HEAD_REMOVAL_REGEX.sub("", chat_content)

                # Clean up any accidental double spaces left behind by the removal
                clean_chat = re.sub(r"\s+", " ", clean_chat).strip()

                print(f"[Forwarding] {clean_chat}")
                send_to_discord(clean_chat)

if __name__ == "__main__":
    try:
        tail_log()
    except KeyboardInterrupt:
        print("\n[*] Stopping chat bridge. Goodbye!")
