# .dotfiles

A collection of personal dotfiles for Linux environments, featuring Oh My Zsh configurations with custom themes, useful plugins, and productivity-enhancing shell setup.

## 📋 Overview

This repository contains my personal configuration files (dotfiles) for setting up a consistent development environment across Linux and Windows systems. The configurations include a fully integrated Oh My Zsh setup with Spaceship theme, custom themes, useful plugins, DNSCrypt-Proxy for secure DNS, and productivity enhancements for a beautiful and functional terminal experience.

## 🚀 Quick Start

Setting up your environment is as simple as running a single command. The master install script handles everything from cloning the repository to executing all necessary setup scripts.

### One-Liner Installation

This command will clone the repository, change into the directory, and execute the installation script.

```bash
git clone https://github.com/MF-Rozi/.dotfiles.git ~/dotfiles && cd ~/dotfiles && chmod +x ./install.sh && ./install.sh
```

### Manual Steps

If you prefer to run the setup scripts individually instead of using the master `install.sh` script:

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/MF-Rozi/.dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

2.  **Run the Zsh setup script:**

    ```bash
    chmod +x scripts/setup-zsh.sh
    ./scripts/setup-zsh.sh
    ```

3.  **Run the dnscrypt-proxy setup script:**
    ```bash
    chmod +x scripts/setup-dnscrypt-proxy.sh
    ./scripts/setup-dnscrypt-proxy.sh
    ```
4.  **Run the port-specific Cloudflare DNS setup (optional):**
    ```bash
    chmod +x scripts/setup-port-cloudflare-dns.sh
    sudo ./scripts/setup-port-cloudflare-dns.sh
    ```

After the scripts finish, restart your terminal to see the changes.

## 📁 Repository Structure

```
.dotfiles/
├── README.md                              # This file
├── install.sh                             # Master installation script
├── zsh/
│   └── .zshrc                            # Main zsh configuration with Oh My Zsh setup
├── oh-my-zsh/
│   └── custom/
│       └── themes/
│           └── mf-rozi.zsh-theme         # Custom theme with git info, RAM usage, and timing
├── dnscrypt-proxy/                        # DNSCrypt-Proxy configuration files
│   ├── dnscrypt-proxy.toml               # Main configuration
│   ├── allowed-ips.txt                   # IP whitelist
│   ├── allowed-names.txt                 # Domain whitelist
│   ├── blocked-ips.txt                   # IP blocklist
│   ├── blocked-names.txt                 # Domain blocklist
│   ├── captive-portals.txt               # Captive portal exceptions
│   ├── cloaking-rules.txt                # DNS cloaking rules
│   └── forwarding-rules.txt              # DNS forwarding rules
├── scripts/                               # Automated setup scripts
│   ├── setup-zsh.sh                      # Zsh and Oh My Zsh installation
│   ├── setup-dnscrypt-proxy.sh           # DNSCrypt-Proxy setup for Arch Linux
│   ├── setup-port-cloudflare-dns.sh      # Route specific ports to Cloudflare DNS
│   ├── asdf-setup.sh                     # ASDF version manager setup
│   └── dev-environment-setup.sh          # Development environment setup
├── shortcuts/
│   └── shortcuts.md                      # Quick reference commands and shortcuts
└── docs/
    ├── Setup-Windows-winget.txt          # Windows application list (winget)
    └── setup-windows.ps1                 # Windows automated setup script
```

## 🎨 Features

### Oh My Zsh Integration

- **Fully configured Oh My Zsh setup** with optimized settings
- **Spaceship Prompt** as the default theme featuring:
  - Username display (configurable)
  - Current directory with git integration
  - Git repository status with branch information
  - Custom RAM usage section on the right prompt
  - Time display on the right prompt
  - Clean and customizable prompt layout
- **Custom mf-rozi theme**(alternative) featuring:
  - Git repository status with clean/dirty indicators
  - Real-time RAM usage monitoring
  - Command execution timing
  - Colorful and informative prompt layout
- **Essential plugins** pre-configured:
  - `git` - Git aliases and functions
  - `zsh-autosuggestions` - Fish-like autosuggestions
  - `zsh-syntax-highlighting` - Command syntax highlighting

### Shell Enhancements

- **Beautiful prompts** with useful system information
- **Performance monitoring** with built-in RAM usage and timing
- **Git integration** with visual status indicators
- **Spaceship Prompt customization** with custom sections
- **Optimized for productivity** with sensible defaults

### Network & Security

- **DNSCrypt-Proxy** configuration for secure and private DNS
  - Custom blocklists and allowlists
  - DNS cloaking and forwarding rules
  - Systemd integration for Arch Linux
- **Port-specific DNS routing** for applications like Minecraft

  - Route traffic from specific ports to Cloudflare DNS
  - Iptables-based packet marking and routing
  - Persistent rules across reboots

  ### Development Tools

- **ASDF version manager** setup script
- **Development environment** automated configuration
- **PATH management** for various development tools

### Windows Support

- **Automated Windows setup** using winget and PowerShell
  - Browser installation (Zen Browser, Chrome)
  - Development tools (VS Code, Git)
  - Utilities (PowerToys, WhatsApp)
  - Acer-specific software (Care Center, Nitro Sense)
  - User-level apps (Spotify with Spicetify)

## 🛠️ Manual Installation

If you prefer to install configurations manually:

### Oh My Zsh Setup

```bash
# Backup existing config if it exists
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null || true

# Copy zsh configuration
cp ~/.dotfiles/zsh/.zshrc ~/.zshrc

# Copy custom theme
cp ~/.dotfiles/oh-my-zsh/custom/themes/mf-rozi.zsh-theme ~/.oh-my-zsh/custom/themes/

# Install plugins if not already installed
[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

## 🎯 Customization

Feel free to fork this repository and customize it to your needs:

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/.dotfiles.git ~/.dotfiles
   ```
3. **Make your changes**
4. **Test thoroughly before committing**

### Spaceship Prompt Customization

You can customize the Spaceship prompt by editing the configuration in `.zshrc`:

```bash
# Show/hide username
SPACESHIP_USER_SHOW="true"  # or "always", "false"

# Customize RAM section
SPACESHIP_RAM_SYMBOL="💾 "  # Change the symbol
SPACESHIP_RAM_COLOR="yellow"  # Change the color

# Modify prompt order
SPACESHIP_PROMPT_ORDER=(
  user
  dir
  git
  line_sep
  char
)
```

## 📝 Planned Enhancements

- [ ] Tmux configuration
- [ ] Neovim/Vim plugin management with modern setup
- [ ] VS Code settings sync and extension list
- [ ] Terminal emulator configurations (Alacritty, Kitty)
- [ ] Additional custom themes and color schemes
- [ ] Git configuration files (.gitconfig, .gitignore_global)
- [ ] Automated backup and restore functionality

## ✅ Completed Features

- ✅ Automated installation script
- ✅ Spaceship Prompt integration
- ✅ DNSCrypt-Proxy configuration
- ✅ Windows setup automation
- ✅ Port-specific DNS routing
- ✅ System-specific installation scripts
- ✅ ASDF version manager setup

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the amazing dotfiles community
- Thanks to the [Spaceship Prompt](https://spaceship-prompt.sh/) team for their beautiful prompt
- Thanks to all the open-source projects that make these configurations possible
- Special thanks to the zsh, Oh My Zsh, and vim communities for their excellent documentation
- DNSCrypt-Proxy for secure DNS resolution

## 📞 Support

If you have any questions or run into issues:

1. Check the [Issues](https://github.com/MF-Rozi/.dotfiles/issues) page
2. Create a new issue if your problem isn't already reported
3. Provide as much detail as possible about your system and the issue

## 💡 Tips

### Recommended Fonts

For the best experience with Spaceship theme and icons, install a Nerd Font:

```bash
# Install JetBrains Mono Nerd Font (recommended)
yay -S nerd-fonts-jetbrains-mono

# Or install other popular Nerd Fonts
yay -S nerd-fonts-fira-code
yay -S nerd-fonts-hack
```

**Happy coding!** 🚀
