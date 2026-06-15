#!/usr/bin/env bash
# Default Applications Setup Script for Arch Linux
# Installs essential CLI tools and system utilities.

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR]${NC} This script should not be run as root. It will use sudo when needed."
    exit 1
fi

# Check if pacman is available
if ! command -v pacman &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} pacman not found. This script targets Arch Linux."
    exit 1
fi

# List of packages to install
PACKAGES=(
    btop
    vnstat
    fastfetch
)

main() {
    echo -e "${BLUE}[INFO]${NC} Updating package databases..."
    sudo pacman -Sy

    echo -e "${BLUE}[INFO]${NC} Installing default applications..."
    for pkg in "${PACKAGES[@]}"; do
        if pacman -Qi "$pkg" &> /dev/null; then
            echo -e "${GREEN}[SUCCESS]${NC} '$pkg' is already installed."
        else
            echo -e "${BLUE}[INFO]${NC} Installing '$pkg'..."
            sudo pacman -S --noconfirm "$pkg"
        fi
    done

    # Optional: Enable systemd services (e.g., vnstat) if installed
    if pacman -Qi vnstat &> /dev/null; then
        echo -e "${BLUE}[INFO]${NC} Enabling and starting vnstat service..."
        sudo systemctl enable --now vnstatd.service
    fi

    echo -e "${GREEN}[SUCCESS]${NC} Default applications setup completed!"
}

main "$@"
