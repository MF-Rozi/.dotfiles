#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Colors for output
GREEN='\033;0;32m'
BLUE='\033[1;34m'
RED='\033;0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} Installing Waydroid & Google Play Setup  ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Get the script's root directory to find the companion services folder
base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Install Waydroid via Pacman
if ! command -v waydroid &> /dev/null; then
    echo -e "${GREEN}➜ Installing Waydroid...${NC}"
    sudo pacman -S --noconfirm waydroid
else
    echo -e "${GREEN}✔ Waydroid is already installed.${NC}"
fi

# 2. Initialize with Google Apps
if [ ! -d "/var/lib/waydroid/images" ] || [ -z "$(ls -A /var/lib/waydroid/images)" ]; then
    echo -e "${GREEN}➜ Initializing Android system image (GAPPS)...${NC}"
    sudo waydroid init -s GAPPS
else
    echo -e "${GREEN}✔ Waydroid image already initialized.${NC}"
fi

# 3. Enable System Container Service
echo -e "${GREEN}➜ Enabling Waydroid container daemon...${NC}"
sudo systemctl enable --now waydroid-container.service

# 4. Enable Multi-Window Mode
echo -e "${GREEN}➜ Enabling Multi-Window Mode for native window dragging...${NC}"
waydroid prop set persist.waydroid.multi_windows true

# 5. Copy and Enable User Session Daemon from services directory
echo -e "${GREEN}➜ Copying and setting up background user session daemon...${NC}"
mkdir -p ~/.config/systemd/user

# Copying directly from your custom services folder
cp "$base_dir/services/waydroid-session.service" ~/.config/systemd/user/

# Reload user daemons and enable the session to start on login
systemctl --user daemon-reload
systemctl --user enable --now waydroid-session.service

echo -e "\n${BLUE}==========================================${NC}"
echo -e "${GREEN}✔ Installation and Daemon Setup Complete!${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "Waydroid is now running silently in the background."
echo -e "Please wait about 1-2 minutes for Android to fully boot internally."
echo -e "\n${RED}==========================================${NC}"
echo -e "${RED} ACTION REQUIRED: GOOGLE PLAY CERTIFICATION ${NC}"
echo -e "${RED}==========================================${NC}"
echo -e "1. Run this exact command to get your Android ID:"
echo -e "   ${GREEN}sudo waydroid shell -- sh -c \"sqlite3 /data/data/*/*/gservices.db 'select value from main where name = \\\"android_id\\\";'\"${NC}"
echo -e ""
echo -e "2. Go to this official link and log in to register the ID:"
echo -e "   ${BLUE}https://www.google.com/android/uncertified${NC}"
echo -e ""
echo -e "3. After 5 minutes, restart the daemon to apply the certification:"
echo -e "   ${GREEN}systemctl --user restart waydroid-session.service${NC}\n"