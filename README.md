# .dotfiles

A collection of personal dotfiles for Linux environments, featuring Oh My Zsh configurations with custom themes, useful plugins, and productivity-enhancing shell setup.

## 📋 Overview

This repository contains my personal configuration files (dotfiles) for setting up a consistent development environment across Linux systems. The configurations include a fully integrated Oh My Zsh setup with custom themes, useful plugins, and productivity enhancements for a beautiful and functional terminal experience.

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

After the scripts finish, restart your terminal to see the changes.

## 📁 Repository Structure

```
.dotfiles/
├── README.md                           # This file
├── zsh/
│   └── .zshrc                         # Main zsh configuration with Oh My Zsh setup
└── oh-my-zsh/
    └── custom/
        └── themes/
            ├── mf-rozi.zsh-theme      # Custom theme with git info, RAM usage, and timing
            └── example.zsh-theme      # Example theme template
```

## 🎨 Features

### Oh My Zsh Integration
- **Fully configured Oh My Zsh setup** with optimized settings
- **Custom mf-rozi theme** featuring:
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
- **Performance monitoring** with built-in timing and resource usage
- **Git integration** with visual status indicators
- **Optimized for productivity** with sensible defaults

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

## 📝 Planned Enhancements

- [ ] Automated installation script
- [ ] Powerlevel10k theme integration option
- [ ] Tmux configuration
- [ ] Neovim/Vim plugin management
- [ ] VS Code settings sync
- [ ] Terminal emulator configurations
- [ ] System-specific installation scripts
- [ ] Automated backup and restore functionality
- [ ] Additional custom themes
- [ ] Git configuration files

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the amazing dotfiles community
- Thanks to all the open-source projects that make these configurations possible
- Special thanks to the zsh and vim communities for their excellent documentation

## 📞 Support

If you have any questions or run into issues:

1. Check the [Issues](https://github.com/MF-Rozi/.dotfiles/issues) page
2. Create a new issue if your problem isn't already reported
3. Provide as much detail as possible about your system and the issue

---

**Happy coding!** 🚀
