#!/usr/bin/env bash
# Install fonts for code editing
# Supports: Linux (apt/dnf/pacman), macOS (Homebrew)
# For manual installation, see docs/FONTS.md

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}[INFO] Installing fonts for VS Code...${NC}"

# Detect operating system
OS="$(uname -s)"
case "$OS" in
    Linux*)
        DISTRO=""
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO="$ID"
        fi
        
        echo -e "${CYAN}[INFO] Detected Linux (${DISTRO:-unknown})${NC}"
        
        # Check for available package managers
        if command -v apt-get &> /dev/null; then
            install_apt
        elif command -v dnf &> /dev/null; then
            install_dnf
        elif command -v pacman &> /dev/null; then
            install_pacman
        else
            install_manual_linux
        fi
        ;;
    
    Darwin*)
        echo -e "${CYAN}[INFO] Detected macOS${NC}"
        install_macos
        ;;
    
    *)
        echo -e "${RED}[ERROR] Unsupported operating system: $OS${NC}"
        echo -e "${YELLOW}Please install fonts manually. See docs/FONTS.md${NC}"
        exit 1
        ;;
esac

# Function to install via apt (Ubuntu/Debian)
install_apt() {
    echo -e "${CYAN}[INFO] Using apt package manager...${NC}"
    
    if ! dpkg -l | grep -q fonts-firacode; then
        echo -e "${CYAN}[INFO] Installing Fira Code...${NC}"
        sudo apt-get update
        sudo apt-get install -y fonts-firacode
    else
        echo -e "${GREEN}[INFO] Fira Code already installed${NC}"
    fi
    
    # JetBrains Mono and Cascadia Code need manual installation or PPA
    echo -e "${YELLOW}[WARN] JetBrains Mono and Cascadia Code require manual installation on apt${NC}"
    echo -e "${YELLOW}       Installing via Nerd Fonts installer...${NC}"
    install_nerd_fonts_installer
}

# Function to install via dnf (Fedora)
install_dnf() {
    echo -e "${CYAN}[INFO] Using dnf package manager...${NC}"
    
    sudo dnf install -y fira-code-fonts || echo -e "${YELLOW}[WARN] Fira Code not available in repos${NC}"
    
    echo -e "${YELLOW}[WARN] JetBrains Mono and Cascadia Code require manual installation${NC}"
    echo -e "${YELLOW}       Installing via Nerd Fonts installer...${NC}"
    install_nerd_fonts_installer
}

# Function to install via pacman (Arch Linux)
install_pacman() {
    echo -e "${CYAN}[INFO] Using pacman package manager...${NC}"
    
    # Check for AUR helper
    if command -v yay &> /dev/null; then
        # Install original fonts
        yay -S --noconfirm ttf-firacode ttf-jetbrains-mono ttf-cascadia-code || true
        # Install Nerd Fonts
        yay -S --noconfirm ttf-firacode-nerd ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd
    elif command -v paru &> /dev/null; then
        # Install original fonts
        paru -S --noconfirm ttf-firacode ttf-jetbrains-mono ttf-cascadia-code || true
        # Install Nerd Fonts
        paru -S --noconfirm ttf-firacode-nerd ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd
    else
        echo -e "${YELLOW}[WARN] No AUR helper found. Installing from official repos...${NC}"
        sudo pacman -S --noconfirm ttf-firacode
        echo -e "${YELLOW}       For Nerd Fonts variants, install yay or paru${NC}"
        echo -e "${YELLOW}       Or use the Nerd Fonts installer below${NC}"
        install_nerd_fonts_installer
    fi
}

# Function to install via Homebrew (macOS)
install_macos() {
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}[ERROR] Homebrew is not installed.${NC}"
        echo -e "${YELLOW}        Install from: https://brew.sh/${NC}"
        echo -e "${YELLOW}        Or install fonts manually. See docs/FONTS.md${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}[INFO] Using Homebrew...${NC}"
    
    # Add fonts cask repo if needed
    brew tap homebrew/cask-fonts 2>/dev/null || true
    
    # Install original fonts (clean versions)
    echo -e "${CYAN}[INFO] Installing original fonts (clean versions)...${NC}"
    brew install --cask font-fira-code 2>/dev/null || echo -e "${YELLOW}[WARN] Fira Code may already be installed${NC}"
    brew install --cask font-jetbrains-mono 2>/dev/null || echo -e "${YELLOW}[WARN] JetBrains Mono may already be installed${NC}"
    brew install --cask font-cascadia-code 2>/dev/null || echo -e "${YELLOW}[WARN] Cascadia Code may already be installed${NC}"
    
    # Install Nerd Fonts (with icons)
    echo -e "${CYAN}[INFO] Installing Nerd Fonts (with icons for terminals)...${NC}"
    brew install --cask font-fira-code-nerd-font 2>/dev/null || echo -e "${YELLOW}[WARN] Fira Code NF may already be installed${NC}"
    brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || echo -e "${YELLOW}[WARN] JetBrains Mono NF may already be installed${NC}"
    brew install --cask font-cascadia-code-nerd-font 2>/dev/null || echo -e "${YELLOW}[WARN] Cascadia Code NF may already be installed${NC}"
}

# Function to install via Nerd Fonts official installer
install_nerd_fonts_installer() {
    echo -e "${CYAN}[INFO] Using Nerd Fonts official installer...${NC}"
    
    # Download and run the installer
    curl -fLo "/tmp/nerd-fonts/install.sh" https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/install.sh
    
    # Create fonts directory if it doesn't exist
    mkdir -p ~/.local/share/fonts
    
    # Install specific fonts (both original and Nerd Fonts versions)
    /tmp/nerd-fonts/install.sh --dest ~/.local/share/fonts --fontconfig FiraCode JetBrainsMono CascadiaCode
    
    # Refresh font cache
    fc-cache -fv ~/.local/share/fonts
    
    rm -rf /tmp/nerd-fonts
}

# Manual installation fallback for Linux
install_manual_linux() {
    echo -e "${YELLOW}[WARN] No supported package manager found.${NC}"
    echo -e "${YELLOW}       Using Nerd Fonts installer...${NC}"
    install_nerd_fonts_installer
}

# Success message
echo ""
echo -e "${GREEN}[SUCCESS] All fonts installed!${NC}"
echo ""
echo -e "Installed fonts:"
echo ""
echo -e "  Original (clean):"
echo -e "    - Fira Code"
echo -e "    - JetBrains Mono"
echo -e "    - Cascadia Code"
echo ""
echo -e "  Nerd Fonts (with icons):"
echo -e "    - Fira Code NF"
echo -e "    - JetBrains Mono NF"
echo -e "    - Cascadia Code NF"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Restart VS Code to detect the new fonts"
echo -e "  2. Fonts are configured in settings/fragments/10-editor.json"
echo -e "  3. See docs/FONTS.md for more information"