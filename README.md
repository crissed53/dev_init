# dev_init

A comprehensive development environment setup script that configures zsh, tmux, neovim, programming languages, and essential development tools.

## Prerequisites

- **Ubuntu/Debian-based system**
- **sudo privileges** (not root access)
- **Internet connection** for downloading packages and tools

## Quick Start

```bash
# Clone and run the setup
git clone <your-repo-url> dev_init
cd dev_init
bash run.sh
```

## Project Structure

```
dev_init/
├── run.sh              # Main entry point
├── env.sh              # Environment variables
├── scripts/            # Installation scripts
│   ├── base.sh         # Core installation logic
│   └── utils.sh        # Helper functions
├── config/             # Configuration files
│   └── dotfiles/       # Dotfiles and config templates
└── README.md           # This file
```

## What Gets Installed

- **Shell**: zsh with oh-my-zsh and pure prompt
- **Editor**: neovim with LazyVim configuration  
- **Terminal**: tmux with gpakosz configuration
- **Languages**: Node.js, Rust, Go, Python (via uv)
- **Tools**: fzf, eza, zoxide, lazygit, dua-cli
- **Container**: Docker CE with plugins

## SSH Setup (with sudo)

If you need to configure SSH for remote access:

```bash
# Set up SSH directory permissions
sudo chmod 700 ~/.ssh
sudo chmod 600 ~/.ssh/authorized_keys

# Configure SSH daemon (requires sudo)
sudo sed -i 's/^#*Port .*/Port 33333/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config  
sudo sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart ssh
```
