#!/usr/bin/env bash
# Configurations Setup Script
# Automatically symlinks directories/files under 'config' directory to '~/.config'.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR]${NC} This script should not be run as root."
    exit 1
fi

DOTFILES_DIR="$HOME/dotfiles"
CONFIGS_DIR="$DOTFILES_DIR/config"
TARGET_DIR="$HOME/.config"

link_item() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        # Check if it's already linking to the correct path
        local target
        target=$(readlink -f "$dest")
        if [ "$target" = "$(realpath "$src")" ]; then
            echo -e "${GREEN}[SUCCESS]${NC} '$dest' is already correctly symlinked."
            return
        fi
        echo -e "${BLUE}[INFO]${NC} Removing existing symlink for '$dest' which points to a different location."
        rm "$dest"
    elif [ -d "$dest" ] && [ -d "$src" ]; then
        echo -e "${BLUE}[INFO]${NC} Destination '$dest' is a directory. Recursively linking contents..."
        for subitem in "$src"/*; do
            if [ -e "$subitem" ]; then
                local subname
                subname=$(basename "$subitem")
                link_item "$subitem" "$dest/$subname"
            fi
        done
        return
    elif [ -e "$dest" ]; then
        # Backup existing file/directory
        echo -e "${BLUE}[INFO]${NC} Backing up existing '$dest' to '$dest.bak'"
        mv "$dest" "$dest.bak"
    fi

    ln -s "$src" "$dest"
    echo -e "${GREEN}[SUCCESS]${NC} Symlinked '$src' to '$dest'"
}

main() {
    echo -e "${BLUE}[INFO]${NC} Setting up config directory symlinks..."

    if [ ! -d "$CONFIGS_DIR" ]; then
        echo -e "${RED}[ERROR]${NC} Config directory not found at '$CONFIGS_DIR'."
        exit 1
    fi

    # Create target directory if it doesn't exist
    mkdir -p "$TARGET_DIR"

    # Loop through all items in config directory
    for item in "$CONFIGS_DIR"/*; do
        if [ -e "$item" ]; then
            local name
            name=$(basename "$item")
            link_item "$item" "$TARGET_DIR/$name"
        fi
    done

    echo -e "${GREEN}[SUCCESS]${NC} Configurations setup completed successfully!"
}

main "$@"

