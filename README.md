# 🚀 macbook-setup

> **Automated macOS setup script for software engineers and DevOps professionals**

[![macOS](https://img.shields.io/badge/macOS-11%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)

A comprehensive, idempotent setup script that configures your Mac for modern software development. Supports both **Intel** and **Apple Silicon** Macs with automatic architecture detection.

## ✨ Features

- 🔍 **Auto-detects architecture** (Intel x86_64 vs Apple Silicon arm64)
- 🔄 **Idempotent** — safe to run multiple times
- 📝 **Comprehensive logging** — saves output to timestamped log files
- ⚙️ **Customizable** — CLI flags to skip components
- 🎯 **Minimal mode** — install only essentials
- 🛡️ **Safe** — backs up configs before modifying

## 📋 What Gets Installed

### Essential Development Tools
- **Homebrew** — Package manager
- **Git** with SSH key generation
- **Modern CLI tools** — `bat`, `eza`, `fd`, `ripgrep`, `fzf`, `jq`, `yq`, `htop`, `tree`
- **Starship** — Modern shell prompt
- **tmux** — Terminal multiplexer

### Programming Languages
- **Python** (3.11 & 3.12) with `pip`, `virtualenv`, `pipenv`, `poetry`
- **Node.js** via `nvm` (version manager)
- **Go** — Latest stable
- **Rust** via `rustup`
- **Java** (OpenJDK 17)

### Cloud & DevOps Tools
- **Docker** — Container platform
- **Kubernetes** — `kubectl`, `kubectx`, `k9s`, `helm`
- **Terraform** — Infrastructure as Code
- **AWS CLI** — Amazon Web Services
- **Google Cloud SDK** — Google Cloud Platform
- **Azure CLI** — Microsoft Azure
- **Ansible** — Configuration management
- **HashiCorp Tools** — `packer`, `vault`, `consul`, `nomad`, `vagrant`

### Databases
- PostgreSQL 15
- MySQL
- Redis
- MongoDB

### IDEs & Editors
- Visual Studio Code
- Neovim
- JetBrains Toolbox

### Productivity Tools
- iTerm2 — Better terminal
- Slack — Team communication
- Zoom — Video conferencing
- Notion — Note-taking
- Rectangle — Window management
- Postman — API testing

### Shell Configuration
- **Oh My Zsh** — Zsh framework
- **Plugins** — autosuggestions, syntax highlighting
- **Aliases** — Convenient shortcuts

## 🚀 Quick Start

### One-Line Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/macbook-setup/main/setup.sh)
```

### Manual Install

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/macbook-setup.git
cd macbook-setup

# Make executable
chmod +x setup.sh

# Run the script
./setup.sh
```

## ⚙️ Usage Options

```bash
./setup.sh [OPTIONS]

Options:
  --skip-cloud       Skip cloud provider tools (AWS, GCP, Azure)
  --skip-databases   Skip database installations
  --minimal          Install only essential tools
  --help             Show help message
```

### Examples

```bash
# Full installation
./setup.sh

# Minimal installation (essentials only)
./setup.sh --minimal

# Skip cloud tools
./setup.sh --skip-cloud

# Skip databases (use Docker containers instead)
./setup.sh --skip-databases

# Combine flags
./setup.sh --skip-cloud --skip-databases
```

## 🏗️ Architecture Support

| Architecture | Status | Homebrew Path |
|--------------|--------|---------------|
| Apple Silicon (M1/M2/M3) | ✅ Supported | `/opt/homebrew` |
| Intel (x86_64) | ✅ Supported | `/usr/local` |

The script automatically detects your Mac's architecture and configures tools accordingly.

## 📦 Post-Installation

After the script completes:

1. **Restart your terminal** or run:
   ```bash
   source ~/.zshrc
   ```

2. **Open Docker.app** to complete Docker setup

3. **Add SSH key to Git providers:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   Copy and add to [GitHub](https://github.com/settings/keys) / [GitLab](https://gitlab.com/-/profile/keys)

4. **Configure cloud providers:**
   ```bash
   # AWS
   aws configure
   
   # Google Cloud
   gcloud init
   
   # Azure
   az login
   ```

5. **Install VS Code extensions** (recommended):
   - Python
   - Docker
   - Kubernetes
   - Terraform
   - GitLens
   - Remote - SSH
   - ESLint
   - Prettier

6. **Restart your Mac** for all system changes to take effect

## 📁 Directory Structure

The script creates:

```
~/Development/
├── projects/     # Your coding projects
├── learning/     # Learning materials
├── tools/        # Custom tools
└── scripts/      # Automation scripts
```

## 🔧 Customization

Edit `setup.sh` to:
- Add/remove tools
- Modify shell configuration
- Change directory structure
- Adjust performance settings

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🐛 Troubleshooting

### Xcode Command Line Tools
If the script exits asking for Xcode tools:
1. Complete the installation popup
2. Re-run the script

### Homebrew Issues
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Docker Not Starting
1. Open Docker.app manually
2. Grant necessary permissions
3. Wait for Docker to fully start

### NVM Not Found
The script adds NVM to `.zshrc`. If issues persist:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

## 💡 Performance Tips

### For Older Macs (2015-2019)
- Use `--skip-databases` and run DBs in Docker
- Limit Docker resources (Settings → Resources)
- Close unused applications
- Keep 10-15% free disk space

### For All Macs
- Disable unused services: `brew services list`
- Stop databases when not needed: `brew services stop <service>`
- Use lightweight terminal tools over GUI apps

## 🔒 Security Recommendations

1. **Enable FileVault** — Full disk encryption
2. **Use strong passwords** — For all accounts
3. **Enable Firewall** — System Settings → Network → Firewall
4. **Keep software updated** — `brew upgrade`
5. **Use 2FA** — Enable on all cloud accounts

## 📚 Resources

- [Git Documentation](https://git-scm.com/doc)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Tutorials](https://learn.hashicorp.com/terraform)
- [Homebrew Documentation](https://docs.brew.sh/)

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📝 License

[MIT License](LICENSE) — Free to use and modify.

## ⭐ Show Your Support

If this script helped you, give it a ⭐️!

---

**Made with ❤️ for the developer community**
