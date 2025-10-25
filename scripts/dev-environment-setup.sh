!#/bin/bash
# Dev Environment Setup Script for Arch Linux
# This script installs and configures essential development tools.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

flutterSetup(){
    # Flutter Setup Using FVM
    if command -v fvm &> /dev/null; then
        echo -e "${GREEN}[SUCCESS]${NC} FVM is already installed."
    else
        echo -e "${BLUE}[INFO]${NC} Installing FVM (Flutter Version Manager)..."
        sudo pacman -S --noconfirm dart
        echo -e "${GREEN}[SUCCESS]${NC} FVM installed successfully."
        if command -v fvm &> /dev/null; then
            echo -e "${GREEN}[SUCCESS]${NC} FVM is now available."
            fvm install stable
            echo -e "${GREEN}[SUCCESS]${NC} Flutter stable version installed."
        else
            echo -e "${RED}[ERROR]${NC} FVM installation failed."
            exit 1
        fi
    fi
}

main() {
    flutterSetup
    echo -e "${GREEN}[SUCCESS]${NC} Development environment setup completed successfully."
    echo "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
}