#!/bin/bash

# Zsh & Oh My Zsh Setup Script
# This script installs Zsh, Oh My Zsh, and links your custom configurations.

set -e # Exit on any error

# --- Configuration ---
DOTFILES_DIR="$HOME/dotfiles"
ZSH_CUSTOM_THEMES_DIR="$HOME/.oh-my-zsh/custom/themes"
ZSHRC_SOURCE="$DOTFILES_DIR/zsh/.zshrc"
ZSHRC_DEST="$HOME/.zshrc"
THEME_SOURCE="$DOTFILES_DIR/oh-my-zsh/custom/themes/mf-rozi.zsh-theme"
THEME_DEST="$ZSH_CUSTOM_THEMES_DIR/mf-rozi.zsh-theme"

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. It will use sudo when needed."
        exit 1
    fi
}

# --- Main Functions ---

install_dependencies() {
    print_status "Installing dependencies (zsh, git, curl)..."
    if ! command -v pacman &> /dev/null; then
        print_error "This script is designed for Arch Linux (pacman not found)."
        exit 1
    fi
    sudo pacman -S --noconfirm zsh git curl
    print_success "Dependencies installed."
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_status "Oh My Zsh is already installed."
    else
        print_status "Installing Oh My Zsh..."
        # Run the installer non-interactively
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed."
    fi
}

link_zshrc() {
    print_status "Setting up .zshrc..."
    # Backup existing .zshrc if it's a real file or a different symlink
    if [ -f "$ZSHRC_DEST" ] && [ ! -L "$ZSHRC_DEST" ]; then
        print_status "Backing up existing .zshrc to .zshrc.bak"
        mv "$ZSHRC_DEST" "$ZSHRC_DEST.bak"
    elif [ -L "$ZSHRC_DEST" ]; then
        print_status "Removing existing .zshrc symlink."
        rm "$ZSHRC_DEST"
    fi
    
    print_status "Creating symlink for .zshrc..."
    ln -s "$ZSHRC_SOURCE" "$ZSHRC_DEST"
    print_success ".zshrc linked successfully."
}

link_theme() {
    print_status "Setting up custom theme..."
    # Create the custom themes directory if it doesn't exist
    mkdir -p "$ZSH_CUSTOM_THEMES_DIR"
    
    # Remove existing theme file or symlink if it exists
    if [ -f "$THEME_DEST" ] || [ -L "$THEME_DEST" ]; then
        print_status "Removing existing theme file/symlink."
        rm "$THEME_DEST"
    fi
    
    print_status "Creating symlink for mf-rozi.zsh-theme..."
    ln -s "$THEME_SOURCE" "$THEME_DEST"
    print_success "Custom theme linked successfully."
}

change_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        print_status "Changing default shell to Zsh..."
        # chsh requires the user's password
        if chsh -s "$(which zsh)"; then
            print_success "Default shell changed to Zsh. Please log out and log back in for the change to take effect."
        else
            print_error "Failed to change shell. Please do it manually."
        fi
    else
        print_status "Default shell is already Zsh."
    fi
}

# --- Main Execution ---
main() {
    check_root
    install_dependencies
    install_oh_my_zsh
    link_zshrc
    link_theme
    change_shell
    
    print_success "Zsh setup complete!"
    print_status "Please restart your terminal or log out and log back in to apply all changes."
}

main "$@"
