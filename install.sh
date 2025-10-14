#!/bin/bash

# ------------------------------------------------------
#  Master Setup Script for M-F-Rozi's Dotfiles
# ------------------------------------------------------
# This script automates the setup of the entire environment
# by executing all the individual setup scripts located
# in the 'scripts' directory.
#
# To run:
# 1. cd ~/dotfiles
# 2. ./install.sh
# ------------------------------------------------------

set -e # Exit immediately if a command exits with a non-zero status.

# --- Colors for Output ---
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Main Logic ---
main() {
    # Get the absolute path of the directory where this script is located
    local base_dir
    base_dir=$(dirname "$(realpath "$0")")
    local scripts_dir="$base_dir/scripts"

    echo -e "${BLUE}Starting dotfiles setup...${NC}"

    if [ ! -d "$scripts_dir" ]; then
        echo -e "${RED}[ERROR]${NC} 'scripts' directory not found at '$scripts_dir'."
        exit 1
    fi

    # Loop through all .sh files in the scripts directory
    for script in "$scripts_dir"/*.sh; do
        if [ -f "$script" ]; then
            local script_name
            script_name=$(basename "$script")
            echo -e "\n${BLUE}--- Executing: $script_name ---${NC}"

            # Make the script executable
            chmod +x "$script"

            # Run the script
            "$script"
        fi
    done

    echo -e "\n${GREEN}✅ All setup scripts executed successfully!${NC}"
    echo "Please restart your terminal to apply all changes."
}

# Run the main function
main
