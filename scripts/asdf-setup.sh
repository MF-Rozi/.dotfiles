#!/bin/env bash
# ASDF Setup Script
# This script installs ASDF version manager and sets up the environment.

set -e  # Exit on any error
NODE_VERSION_DEFAULT="Latest:20"

check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "\033[0;31m[ERROR]\033[0m This script should not be run as root. It will use sudo when needed."
        exit 1
    fi
}
check_arch() {
    if ! command -v pacman &> /dev/null; then
        echo -e "\033[0;31m[ERROR]\033[0m This script is designed for Arch Linux (pacman not found)."
        exit 1
    fi
}

check_asdf_and_install(){
    if command -v asdf &> /dev/null; then
        echo -e "\033[0;32m[SUCCESS]\033[0m ASDF is already installed."
    else
        yay -S --noconfirm asdf-vm
        echo -e "\033[0;32m[SUCCESS]\033[0m ASDF installed successfully."
    fi
}

setup_asdf() {
    local plugins=(
        "nodejs"
    )
    for plugin in "${plugins[@]}"; do
        if asdf plugin-list | grep -q "^${plugin}$"; then
            echo -e "\033[0;32m[SUCCESS]\033[0m ASDF plugin '${plugin}' is already added."
        else
            asdf plugin-add "$plugin"
            if [ "$plugin" == "nodejs" ]; then
                asdf install nodejs $NODE_VERSION_DEFAULT
                asdf global nodejs $NODE_VERSION_DEFAULT
            fi
            echo -e "\033[0;32m[SUCCESS]\033[0m ASDF plugin '${plugin}' added successfully."
        fi
    done
    

    
}
main() {
    check_root
    check_arch
    check_asdf_and_install
    setup_asdf
    echo -e "\033[0;32m[SUCCESS]\033[0m ASDF setup completed successfully."
    echo "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
}