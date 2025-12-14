#!/bin/bash

# --- Dependency Installation Script ---
# This script detects the system's package manager and installs zsh, git, and ranger.
# It also clones the Powerlevel10k theme.

echo "Starting dependency installation..."

# Step 1: Detect package manager
PACKAGE_MANAGER=""
if command -v apt &> /dev/null; then
    PACKAGE_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PACKAGE_MANAGER="pacman"
else
    echo "Error: Could not detect a supported package manager (apt, dnf, pacman)."
    echo "Please install zsh, git, and ranger manually."
    exit 1
fi

echo "Detected package manager: $PACKAGE_MANAGER"

# Step 2: Function to install a package
install_package() {
    local PACKAGE_NAME=$1
    if ! command -v "$PACKAGE_NAME" &> /dev/null; then
        echo "Attempting to install $PACKAGE_NAME..."
        case "$PACKAGE_MANAGER" in
            "apt")
                sudo apt update && sudo apt install -y "$PACKAGE_NAME"
                ;;
            "dnf")
                sudo dnf install -y "$PACKAGE_NAME"
                ;;
            "pacman")
                sudo pacman -Syu --noconfirm "$PACKAGE_NAME"
                ;;
        esac
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to install $PACKAGE_NAME. Please install it manually if needed."
        else
            echo "$PACKAGE_NAME installed successfully."
        fi
    else
        echo "$PACKAGE_NAME is already installed."
    fi
}

# Step 3: Install core dependencies
install_package zsh
install_package git
install_package ranger

# Step 4: Install Powerlevel10k theme
echo "Checking for Powerlevel10k theme..."
P10K_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
P10K_THEME_PATH="$P10K_CUSTOM_DIR/themes/powerlevel10k"

# Ensure custom directory exists if Oh My Zsh is used
if [ -d "$P10K_CUSTOM_DIR" ] && [ ! -d "$P10K_THEME_PATH" ]; then
    echo "Cloning Powerlevel10k into Oh My Zsh custom themes..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_THEME_PATH"
elif [ ! -d "$HOME/.config/powerlevel10k" ]; then
    echo "Cloning Powerlevel10k into ~/.config/powerlevel10k..."
    mkdir -p "$HOME/.config"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.config/powerlevel10k"
    P10K_THEME_PATH="$HOME/.config/powerlevel10k"
else
    echo "Powerlevel10k appears to be already cloned."
fi

echo ""
echo "--- Installation Summary ---"
echo "Core packages (zsh, git, ranger) have been checked and installed if missing."
echo "Powerlevel10k theme has been cloned (if missing)."
echo ""
echo "--- Next Steps: Manual Configuration Required ---"
echo "1. Make Zsh your default shell (if not already):"
echo "   chsh -s $(which zsh)"
echo ""
echo "2. Install a Nerd Font (e.g., MesloLGS NF) for Powerlevel10k icons. This is crucial for proper display."
echo "   - Download from: https://github.com/ryanoasis/nerd-fonts/releases/latest"
echo "   - Unzip the .ttf files and move them to ~/.local/share/fonts/ (create the directory if it doesn't exist)."
echo "   - Run 'fc-cache -fv' to update your font cache."
echo "   - Configure your terminal emulator to use the installed Nerd Font."
echo ""
echo "3. Copy your configuration files:"
echo "   - For Zsh (p10k.zsh and zshrc):"
echo "     cp /mnt/c/Users/User/Desktop/Code/zshrc ~/.zshrc"
echo "     cp /mnt/c/Users/User/Desktop/Code/p10k.zsh ~/.p10k.zsh"
echo "     # After copying ~/.zshrc, you may need to source it or start a new Zsh session:"
echo "     # source ~/.zshrc"
echo ""
echo "   - For Ranger (rifle.conf):"
echo "     mkdir -p ~/.config/ranger"
echo "     cp /mnt/c/Users/User/Desktop/Code/rifle.conf ~/.config/ranger/rifle.conf"
echo ""
echo "   - For rc.conf (adjust path if this is for a specific application):"
echo "     cp /mnt/c/Users/User/Desktop/Code/rc.conf ~/.config/rc.conf"
echo ""
echo "Installation script finished. Please follow the 'Next Steps' to complete your setup."
