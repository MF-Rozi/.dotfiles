# .dotfiles

A collection of personal dotfiles for Linux environments, featuring zsh configurations, themes, and essential development tools setup.

## 📋 Overview

This repository contains my personal configuration files (dotfiles) for setting up a consistent development environment across Linux systems. The configurations focus on enhancing productivity and providing a beautiful, functional terminal experience.

## 🚀 Quick Start

### Prerequisites

- Linux-based operating system (Ubuntu, Debian, Arch, etc.)
- Git
- Zsh shell (will be installed if not present)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MF-Rozi/.dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Run the installation script:**
   ```bash
   # Make the install script executable (when available)
   chmod +x install.sh
   ./install.sh
   ```

3. **Restart your terminal or source the configuration:**
   ```bash
   source ~/.zshrc
   ```

## 📁 Repository Structure

```
.dotfiles/
├── README.md              # This file
├── install.sh             # Installation script (coming soon)
├── zsh/
│   ├── .zshrc            # Main zsh configuration
│   ├── aliases.zsh       # Custom aliases
│   ├── functions.zsh     # Custom functions
│   └── themes/           # Custom zsh themes
├── git/
│   └── .gitconfig        # Git configuration
├── vim/
│   └── .vimrc            # Vim configuration
└── scripts/              # Utility scripts
```

## 🎨 Features

### Zsh Configuration
- **Custom themes**: Beautiful and informative prompt themes
- **Aliases**: Productivity-boosting command shortcuts
- **Functions**: Useful shell functions for development
- **Plugin management**: Support for popular zsh frameworks

### Git Configuration
- Enhanced git aliases for faster workflow
- Beautiful git log formatting
- Useful git configurations for development

### Development Tools
- Vim/Neovim configurations
- Terminal color schemes
- Development environment setup scripts

## 🛠️ Manual Installation

If you prefer to install configurations manually:

### Zsh Setup
```bash
# Backup existing config
cp ~/.zshrc ~/.zshrc.backup

# Symlink the new configuration
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
```

### Git Setup
```bash
# Backup existing config
cp ~/.gitconfig ~/.gitconfig.backup

# Symlink the new configuration
ln -sf ~/.dotfiles/git/.gitconfig ~/.gitconfig
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

## 📝 Coming Soon

- [ ] Oh My Zsh integration
- [ ] Powerlevel10k theme configuration
- [ ] Tmux configuration
- [ ] Neovim/Vim plugin management
- [ ] VS Code settings sync
- [ ] Terminal emulator configurations
- [ ] System-specific installation scripts
- [ ] Automated backup and restore functionality

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