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
# Change SSH port
sudo sed -i '/^#\?Port /c\Port 33333' /etc/ssh/sshd_config

# Root login only with keys
sudo sed -i '/^#\?PermitRootLogin /c\PermitRootLogin prohibit-password' /etc/ssh/sshd_config

# Disable password login
sudo sed -i '/^#\?PasswordAuthentication /c\PasswordAuthentication no' /etc/ssh/sshd_config

# Enable pubkey auth
sudo sed -i '/^#\?PubkeyAuthentication /c\PubkeyAuthentication yes' /etc/ssh/sshd_config

# Set authorized keys file
sudo sed -i '/^#\?AuthorizedKeysFile /c\AuthorizedKeysFile .ssh/authorized_keys' /etc/ssh/sshd_config


chmod 700 /root
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh

```
