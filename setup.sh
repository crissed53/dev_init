#!/bin/bash

# Development Environment Setup Script
# Configures a complete development environment with sudo privileges

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on supported system
check_system() {
    print_status "Checking system compatibility..."
    
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "This script only supports Linux systems"
        exit 1
    fi
    
    if ! command -v apt-get &> /dev/null; then
        print_error "This script requires apt-get (Ubuntu/Debian-based system)"
        exit 1
    fi
    
    print_success "System compatibility verified"
}

# Check sudo privileges
check_sudo() {
    print_status "Checking sudo privileges..."
    
    # Check if user is root (not recommended)
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root is not recommended. Consider using a regular user with sudo privileges."
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Setup cancelled"
            exit 1
        fi
    fi
    
    # Test sudo access
    if ! sudo -n true 2>/dev/null; then
        print_status "Testing sudo access (you may be prompted for password)..."
        if ! sudo true; then
            print_error "This script requires sudo privileges. Please ensure your user has sudo access."
            exit 1
        fi
    fi
    
    print_success "Sudo privileges verified"
}

# Check internet connectivity
check_internet() {
    print_status "Checking internet connectivity..."
    
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No internet connection. Please check your network settings."
        exit 1
    fi
    
    print_success "Internet connectivity verified"
}

# Check available disk space (at least 2GB recommended)
check_disk_space() {
    print_status "Checking available disk space..."
    
    available_space=$(df . | tail -1 | awk '{print $4}')
    required_space=$((2 * 1024 * 1024)) # 2GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        print_warning "Low disk space detected. At least 2GB is recommended."
        print_warning "Available: $(($available_space / 1024 / 1024))GB"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Setup cancelled due to insufficient disk space"
            exit 1
        fi
    fi
    
    print_success "Sufficient disk space available"
}

# Update package lists
update_packages() {
    print_status "Updating package lists..."
    
    if sudo apt-get update; then
        print_success "Package lists updated"
    else
        print_error "Failed to update package lists"
        exit 1
    fi
}

# Main setup function
main() {
    echo "============================================"
    echo "    Development Environment Setup"
    echo "============================================"
    echo
    
    # Pre-flight checks
    check_system
    check_sudo
    check_internet
    check_disk_space
    update_packages
    
    echo
    print_success "All pre-flight checks passed!"
    echo
    
    # Show what will be installed
    echo "This setup will install:"
    echo "  • zsh with oh-my-zsh and pure prompt"
    echo "  • tmux with gpakosz configuration"
    echo "  • neovim with LazyVim configuration"
    echo "  • Node.js, Rust, Go, Python (uv)"
    echo "  • Development tools (fzf, eza, zoxide, lazygit)"
    echo "  • Docker CE with plugins"
    echo
    print_status "Installation uses parallel processing for faster setup!"
    echo
    
    # Confirm installation
    read -p "Do you want to proceed with the installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_warning "Setup cancelled by user"
        exit 0
    fi
    
    # Run the main installation
    print_status "Starting development environment setup..."
    
    if bash run.sh; then
        echo
        print_success "Development environment setup completed successfully!"
        echo
        print_status "Please restart your terminal or run 'source ~/.zshrc' to use the new shell"
        print_status "You may need to log out and back in for all changes to take effect"
    else
        print_error "Setup failed. Please check the error messages above."
        exit 1
    fi
}

# Run main function
main "$@"