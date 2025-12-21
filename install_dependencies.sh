#!/bin/bash

# --- Dependency Installation Script ---
export EDITOR="code --wait"
# Répertoire où se trouve le script et tes fichiers de config
BASE_DIR=$(dirname "$(readlink -f "$0")")

echo "Starting dependency installation from: $BASE_DIR"

# Step 1: Detect package manager
PACKAGE_MANAGER=""
if command -v apt &> /dev/null; then
    PACKAGE_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PACKAGE_MANAGER="pacman"
else
    echo "Error: Could not detect a supported package manager."
    exit 1
fi

# Step 2: Function to install a package
install_package() {
    local PACKAGE_NAME=$1
    if ! command -v "$PACKAGE_NAME" &> /dev/null; then
        case "$PACKAGE_MANAGER" in
            "apt") sudo apt update && sudo apt install -y "$PACKAGE_NAME" ;;
            "dnf") sudo dnf install -y "$PACKAGE_NAME" ;;
            "pacman") sudo pacman -Syu --noconfirm "$PACKAGE_NAME" ;;
        esac
    fi
}




# --- Configuration de la police du Terminal (GNOME Terminal) ---
echo "Configuring terminal font to Fira Code..."

# On récupère l'ID du profil par défaut du terminal
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# On active l'utilisation d'une police personnalisée
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/use-custom-font true

# On définit la police sur Fira Code Retina (taille 12)
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/font "'Fira Code Retina 12'"

echo "Terminal font updated!"







# Step 3: Install core dependencies
install_package zsh
install_package git
install_package ranger
install_package fzf
install_package ripgrep
install_package btop
install_package ncdu 
install_package tldr
install_package i3


# --- Install Node.js and NPM ---
echo "Checking for Node.js and NPM..."
if ! command -v npm &> /dev/null; then
    echo "Installing Node.js and NPM..."
    # Installation de la version LTS (Long Term Support)
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js/NPM already installed."
fi

# --- Install Gemini CLI ---
if command -v npm &> /dev/null; then
    if ! command -v gemini-chat &> /dev/null; then
        echo "Installing Gemini CLI..."
        sudo npm install -g @google/generative-ai-cli
    fi
fi

# --- Install lazygit ---
if ! command -v lazygit &> /dev/null; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*"')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    sudo tar xf lazygit.tar.gz -C /usr/local/bin lazygit
    rm lazygit.tar.gz
fi

# Step 4: Install Powerlevel10k theme
P10K_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
P10K_THEME_PATH="$P10K_CUSTOM_DIR/themes/powerlevel10k"

if [ ! -d "$P10K_THEME_PATH" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_THEME_PATH" 2>/dev/null || \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.config/powerlevel10k"
fi

# --- STEP 5: SYNC CONFIG FILES & VSCODE ---

echo "Applying configuration files..."

# 5.1 Zsh Config
[ -f "$BASE_DIR/zshrc" ] && cp "$BASE_DIR/zshrc" "$HOME/.zshrc"
[ -f "$BASE_DIR/p10k.zsh" ] && cp "$BASE_DIR/p10k.zsh" "$HOME/.p10k.zsh"

# 5.2 Ranger Config
mkdir -p "$HOME/.config/ranger"
[ -f "$BASE_DIR/rifle.conf" ] && cp "$BASE_DIR/rifle.conf" "$HOME/.config/ranger/rifle.conf"
[ -f "$BASE_DIR/rc.conf" ] && cp "$BASE_DIR/rc.conf" "$HOME/.config/ranger/rc.conf"

# 5.3 VS Code Extensions
if command -v code &> /dev/null; then
    if [ -f "$BASE_DIR/extensions_vscode.zip" ]; then
        echo "Extracting VS Code extensions..."
        mkdir -p "$HOME/.vscode/extensions"
        # On extrait directement dans le dossier des extensions
        unzip -o "$BASE_DIR/extensions_vscode.zip" -d "$HOME/.vscode/extensions/"
    fi

    # 5.4 VS Code Settings (En dernier comme demandé)
    echo "Applying VS Code settings.json..."
    # Chemin standard pour VS Code sur Linux (Flatpak ou .deb)
    VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
    [ -d "$HOME/.var/app/org.visualstudio.code/config/Code/User" ] && VSCODE_CONFIG_DIR="$HOME/.var/app/org.visualstudio.code/config/Code/User"
    
    mkdir -p "$VSCODE_CONFIG_DIR"
    [ -f "$BASE_DIR/settings.json" ] && cp "$BASE_DIR/settings.json" "$VSCODE_CONFIG_DIR/settings.json"
else
    echo "Warning: VS Code not found. Skipping extensions and settings."
fi

echo "Installation and Config Sync complete!"
echo "Please run: chsh -s $(which zsh) and restart your terminal."