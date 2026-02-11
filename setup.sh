#!/bin/bash

################################################################################
# Universal MacBook Setup Script for Software Engineering & Cloud DevOps
# Supports: Intel (x86_64) and Apple Silicon (arm64)
# Author: macbook-setup contributors
# License: MIT
################################################################################

# Note: We don't use 'set -e' because we want to continue installing other packages
# even if some fail or timeout. Each installation handles errors gracefully.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Helper function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Custom timeout function for macOS (since 'timeout' command doesn't exist)
run_with_timeout() {
    local timeout_duration=$1
    shift
    local command_to_run=("$@")
    
    # Run command in background
    "${command_to_run[@]}" &
    local cmd_pid=$!
    
    # Wait for command with timeout
    local count=0
    while kill -0 $cmd_pid 2>/dev/null; do
        if [ $count -ge $timeout_duration ]; then
            # Timeout reached, kill the process
            kill -TERM $cmd_pid 2>/dev/null
            sleep 1
            kill -KILL $cmd_pid 2>/dev/null
            wait $cmd_pid 2>/dev/null
            return 124  # timeout exit code
        fi
        sleep 1
        ((count++))
    done
    
    # Command finished, get exit code
    wait $cmd_pid
    return $?
}

# Helper function to install brew packages with timeout
brew_install_with_timeout() {
    local timeout_duration=60
    local package="$1"
    
    log_info "Installing $package (with ${timeout_duration}s timeout)..."
    
    # Run brew install with timeout
    if run_with_timeout "$timeout_duration" brew install "$package"; then
        log_success "$package installed successfully"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_error "$package installation timed out after ${timeout_duration}s"
            log_warning "You can try installing manually later: brew install $package"
        else
            log_error "$package installation failed"
        fi
        return 1
    fi
}

# Helper function to install brew cask packages with timeout
brew_install_cask_with_timeout() {
    local timeout_duration=120
    local package="$1"
    
    log_info "Installing $package (cask, with ${timeout_duration}s timeout)..."
    
    # Run brew install --cask with timeout
    if run_with_timeout "$timeout_duration" brew install --cask "$package"; then
        log_success "$package installed successfully"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_error "$package installation timed out after ${timeout_duration}s"
            log_warning "You can try installing manually later: brew install --cask $package"
        else
            log_error "$package installation failed"
        fi
        return 1
    fi
}

# Parse command line arguments
SKIP_CLOUD=false
SKIP_DATABASES=false
MINIMAL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-cloud) SKIP_CLOUD=true ;;
        --skip-databases) SKIP_DATABASES=true ;;
        --minimal) MINIMAL=true ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-cloud       Skip cloud provider tools (AWS, GCP, Azure)"
            echo "  --skip-databases   Skip database installations"
            echo "  --minimal          Install only essential tools"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run with --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Setup logging to file
LOGFILE="$HOME/macbook-setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    ARCH_NAME="Apple Silicon"
    BREW_PREFIX="/opt/homebrew"
elif [[ "$ARCH" == "x86_64" ]]; then
    ARCH_NAME="Intel"
    BREW_PREFIX="/usr/local"
else
    log_error "Unknown architecture: $ARCH"
    exit 1
fi

# Check macOS version
macos_version=$(sw_vers -productVersion)
macos_major=$(echo "$macos_version" | cut -d. -f1)
if [[ "$macos_major" -lt 11 ]]; then
    log_warning "macOS $macos_version detected. Some tools require macOS 11+"
    log_warning "Consider updating to a newer macOS version for best compatibility"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log_info "========================================="
log_info "MacBook Setup Script"
log_info "========================================="
log_info "Architecture: $ARCH_NAME ($ARCH)"
log_info "macOS Version: $macos_version"
log_info "CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
log_info "Log file: $LOGFILE"
log_info "========================================="
echo ""

################################################################################
# 1. System Updates
################################################################################
log_info "Step 1: Checking for system updates..."
log_warning "Please ensure you've updated macOS through System Settings first"
echo ""

################################################################################
# 2. Install Xcode Command Line Tools
################################################################################
log_info "Step 2: Installing Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
    log_success "Xcode Command Line Tools already installed"
else
    xcode-select --install
    log_warning "Please complete the Xcode Command Line Tools installation and re-run this script"
    exit 0
fi
echo ""

################################################################################
# 3. Install Homebrew
################################################################################
log_info "Step 3: Installing Homebrew..."
if command -v brew &>/dev/null; then
    log_success "Homebrew already installed at $(which brew)"
    brew update
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for current session
    if [[ "$ARCH" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    log_success "Homebrew installed successfully"
fi
echo ""

################################################################################
# 4. Install Essential Development Tools
################################################################################
log_info "Step 4: Installing essential development tools..."

# Version control
if command_exists git; then
    log_success "Git already installed ($(git --version 2>/dev/null))"
else
    brew_install_with_timeout git
fi

# Shell improvements
log_info "Installing modern shell tools..."
if ! command_exists zsh; then
    brew_install_with_timeout zsh
else
    log_success "zsh already installed"
fi

if ! brew list zsh-completions &>/dev/null; then
    brew_install_with_timeout zsh-completions
else
    log_success "zsh-completions already installed"
fi

if ! command_exists starship; then
    brew_install_with_timeout starship
else
    log_success "starship already installed"
fi

# Terminal multiplexer
if ! command_exists tmux; then
    brew_install_with_timeout tmux
else
    log_success "tmux already installed"
fi

# Modern CLI tools
log_info "Installing modern CLI utilities..."
declare -a cli_tools=("bat" "eza" "fd" "ripgrep" "fzf" "jq" "yq" "htop" "tree" "wget" "curl")

for tool in "${cli_tools[@]}"; do
    if ! command_exists "$tool"; then
        brew_install_with_timeout "$tool" || true  # Continue even if one fails
    else
        log_success "$tool already installed"
    fi
done

log_success "Essential development tools installed"
echo ""

if [[ "$MINIMAL" == true ]]; then
    log_info "Minimal installation mode - skipping optional components"
    log_info "Jumping to shell configuration..."
    echo ""
else

################################################################################
# 5. Install Programming Languages & Runtimes
################################################################################
log_info "Step 5: Installing programming languages and runtimes..."

# Python
if command_exists python3; then
    log_success "Python already installed ($(python3 --version 2>/dev/null))"
else
    log_info "Installing Python..."
    brew_install_with_timeout python@3.11 || true
    brew_install_with_timeout python@3.12 || true
fi

if command_exists pip3; then
    pip3 install --upgrade pip
    pip3 install virtualenv pipenv poetry
fi


# Node.js (via nvm for version management)
log_info "Installing Node.js via nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    log_success "Node.js installed via nvm"
else
    log_success "nvm already installed"
fi


# Go
if command_exists go; then
    log_success "Go already installed ($(go version 2>/dev/null | awk '{print $3}'))"
else
    log_info "Installing Go..."
    brew_install_with_timeout go
fi

# Rust
if command_exists rustc; then
    log_success "Rust already installed ($(rustc --version 2>/dev/null | awk '{print $2}'))"
else
    log_info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Java (OpenJDK)
if command_exists java; then
    log_success "Java already installed ($(java -version 2>&1 | head -n 1))"
else
    log_info "Installing Java..."
    brew_install_with_timeout openjdk@17
fi

log_success "Programming languages installed"
echo ""

################################################################################
# 6. Install Cloud & DevOps Tools
################################################################################
if [[ "$SKIP_CLOUD" == false ]]; then
    log_info "Step 6: Installing cloud and DevOps tools..."

    # Docker
    if [ -d "/Applications/Docker.app" ]; then
        log_success "Docker already installed"
    else
        brew_install_cask_with_timeout docker || true
        log_warning "Please open Docker.app to complete setup"
    fi

    # Kubernetes tools
    log_info "Installing Kubernetes tools..."
    declare -a k8s_tools=("kubectl" "kubectx" "k9s" "helm")
    for tool in "${k8s_tools[@]}"; do
        if ! command_exists "$tool"; then
            brew_install_with_timeout "$tool" || true
        else
            log_success "$tool already installed"
        fi
    done

    # Terraform
    if command_exists terraform; then
        log_success "Terraform already installed"
    else
        brew_install_with_timeout terraform || true
    fi

    # AWS CLI
    if command_exists aws; then
        log_success "AWS CLI already installed"
    else
        brew_install_with_timeout awscli || true
    fi

    # Google Cloud SDK
    if command_exists gcloud; then
        log_success "Google Cloud SDK already installed"
    else
        brew_install_cask_with_timeout google-cloud-sdk || true
    fi

    # Azure CLI
    if command_exists az; then
        log_success "Azure CLI already installed"
    else
        brew_install_with_timeout azure-cli || true
    fi

    # Ansible
    if command_exists ansible; then
        log_success "Ansible already installed"
    else
        brew_install_with_timeout ansible || true
    fi

    # Other DevOps tools
    log_info "Installing additional DevOps tools..."
    declare -a devops_tools=("packer" "vault" "consul" "nomad" "vagrant")
    for tool in "${devops_tools[@]}"; do
        if ! command_exists "$tool"; then
            brew_install_with_timeout "$tool" || true
        else
            log_success "$tool already installed"
        fi
    done

    log_success "Cloud & DevOps tools installed"
    echo ""
else
    log_info "Step 6: Skipping cloud tools (--skip-cloud flag)"
    echo ""
fi

################################################################################
# 7. Install Database Tools
################################################################################
if [[ "$SKIP_DATABASES" == false ]]; then
    log_info "Step 7: Installing database tools..."

    declare -a databases=("postgresql@15" "mysql" "redis" "mongodb-community")
    for db in "${databases[@]}"; do
        if ! brew list "$db" &>/dev/null; then
            brew_install_with_timeout "$db" || true
        else
            log_success "$db already installed"
        fi
    done

    log_success "Database tools installed"
    log_info "Note: Databases are not auto-started. Use 'brew services start <db>' when needed"
    echo ""
else
    log_info "Step 7: Skipping databases (--skip-databases flag)"
    echo ""
fi

################################################################################
# 8. Install IDEs and Editors
################################################################################
log_info "Step 8: Installing IDEs and editors..."

# Visual Studio Code
if [ -d "/Applications/Visual Studio Code.app" ]; then
    log_success "Visual Studio Code already installed"
else
    brew_install_cask_with_timeout visual-studio-code || true
fi

# Vim/Neovim
if command_exists nvim; then
    log_success "Neovim already installed"
else
    brew_install_with_timeout neovim || true
fi

# JetBrains Toolbox (for IntelliJ, PyCharm, etc.)
if [ -d "/Applications/JetBrains Toolbox.app" ]; then
    log_success "JetBrains Toolbox already installed"
else
    brew_install_cask_with_timeout jetbrains-toolbox || true
fi

log_success "IDEs and editors installed"
echo ""

################################################################################
# 9. Install Communication & Productivity Tools
################################################################################
log_info "Step 9: Installing communication and productivity tools..."

declare -a cask_apps=("slack" "zoom" "notion" "rectangle" "iterm2" "postman")
for app in "${cask_apps[@]}"; do
    # Check if app is already installed (basic check)
    if brew list --cask "$app" &>/dev/null; then
        log_success "$app already installed"
    else
        brew_install_cask_with_timeout "$app" || true
    fi
done

log_success "Communication & productivity tools installed"
echo ""

fi  # End of non-minimal installation

################################################################################
# 10. Configure Git
################################################################################
log_info "Step 10: Configuring Git..."

read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global init.defaultBranch main
git config --global core.editor "vim"
git config --global pull.rebase false

# Generate SSH key for Git
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    log_info "Generating SSH key for Git..."
    ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"
    log_success "SSH key generated at ~/.ssh/id_ed25519.pub"
    log_warning "Add this key to your GitHub/GitLab account:"
    cat "$HOME/.ssh/id_ed25519.pub"
else
    log_success "SSH key already exists"
fi

log_success "Git configured"
echo ""

################################################################################
# 11. Configure Shell (zsh with Oh My Zsh)
################################################################################
log_info "Step 11: Configuring shell..."

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
else
    log_success "Oh My Zsh already installed"
fi

# Install zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Backup existing .zshrc
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backed up existing .zshrc"
fi

# Update Oh My Zsh plugins in .zshrc (replace existing plugins line)
if grep -q "^plugins=" "$HOME/.zshrc"; then
    sed -i '' 's/^plugins=.*/plugins=(git docker kubectl terraform aws gcloud ansible zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
else
    echo 'plugins=(git docker kubectl terraform aws gcloud ansible zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
fi

# Add custom configurations (only if not already present)
if ! grep -q "# === macbook-setup Config ===" "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << EOF

# === macbook-setup Config ===

# NVM configuration
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \\. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \\. "\$NVM_DIR/bash_completion"

# Rust configuration
[ -f "\$HOME/.cargo/env" ] && source "\$HOME/.cargo/env"

# Go configuration
export GOPATH="\$HOME/go"
export PATH="\$PATH:\$GOPATH/bin"

# Homebrew ($ARCH_NAME)
eval "\$($BREW_PREFIX/bin/brew shellenv)"

# Starship prompt
command -v starship &>/dev/null && eval "\$(starship init zsh)"

# Aliases - DISABLED to allow both traditional and modern tools to coexist
# Uncomment any aliases you want to use:
# alias ls='eza'
# alias ll='eza -la'
# alias la='eza -la'
# alias cat='bat'
# alias find='fd'
# alias grep='rg'
# alias k='kubectl'
#
# Modern CLI tools are installed and available by their actual names:
# - eza (modern ls with colors, icons, git status)
# - bat (cat with syntax highlighting)
# - fd (faster, simpler find)
# - rg/ripgrep (faster grep)
# - fzf (fuzzy finder)

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# === End macbook-setup Config ===
EOF
    log_success "Custom shell configurations added"
else
    log_info "Custom shell configurations already present, skipping"
fi

log_success "Shell configured"
echo ""

################################################################################
# 12. Create Development Directory Structure
################################################################################
log_info "Step 12: Creating development directory structure..."

mkdir -p "$HOME/Development/"{projects,learning,tools,scripts}
mkdir -p "$HOME/.config"

log_success "Development directories created"
echo ""

################################################################################
# 13. Performance Optimizations
################################################################################
log_info "Step 13: Applying performance optimizations..."

# Disable animations
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write -g QLPanelAnimationDuration -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide-delay -float 0

# Disable transparency
defaults write com.apple.universalaccess reduceTransparency -bool true

# Speed up Mission Control
defaults write com.apple.dock expose-animation-duration -float 0.1

log_success "Performance optimizations applied"
log_warning "You may need to restart for all changes to take effect"
echo ""

################################################################################
# Final Steps & Summary
################################################################################
log_success "========================================="
log_success "MacBook setup complete!"
log_success "========================================="
echo ""

# Show installed versions
log_info "Installed versions:"
echo "  Python: $(python3 --version 2>/dev/null || echo 'N/A')"
echo "  Node: $(node --version 2>/dev/null || echo 'N/A')"
echo "  Go: $(go version 2>/dev/null | awk '{print $3}' || echo 'N/A')"
echo "  Rust: $(rustc --version 2>/dev/null | awk '{print $2}' || echo 'N/A')"
echo "  Docker: $(docker --version 2>/dev/null || echo 'N/A (open Docker.app)')"
echo "  Git: $(git --version 2>/dev/null || echo 'N/A')"
echo ""

log_info "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Open Docker.app to complete Docker setup"
echo "  3. Add your SSH key to GitHub/GitLab (displayed above)"
if [[ "$SKIP_CLOUD" == false ]]; then
echo "  4. Configure cloud provider credentials:"
echo "     - AWS: aws configure"
echo "     - GCP: gcloud init"
echo "     - Azure: az login"
fi
echo "  5. Install VS Code extensions for your workflow"
echo "  6. Consider restarting your Mac for all changes to take effect"
echo ""
log_info "Log saved to: $LOGFILE"
log_info "Happy coding! 🚀"
