#!/bin/bash

# --- SCRIPT DE RÉPARATION TOTALE (AVEC NVM) ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
export NVM_DIR="$HOME/.nvm"

echo "🛑 1. NETTOYAGE TOTAL..."
# On supprime tout ce qui pourrait créer des conflits
rm -rf "$HOME/.zshrc" "$HOME/.p10k.zsh" "$HOME/.oh-my-zsh" "$HOME/.nvm"
# On nettoie les paquets node système qui font conflit
sudo apt-get remove --purge -y nodejs npm node-agent-base 2>/dev/null
sudo apt-get autoremove -y

echo "📦 2. INSTALLATION DES OUTILS SYSTÈME..."
sudo apt update
sudo apt install -y zsh git curl unzip fonts-firacode tree ranger eza fzf ripgrep btop build-essential

echo "🔡 3. INSTALLATION FIRA CODE NERD FONT..."
mkdir -p ~/.local/share/fonts
curl -L -o ~/.local/share/fonts/FiraCodeNerdFont-Retina.ttf https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Retina/FiraCodeNerdFont-Retina.ttf
fc-cache -fv

echo "⚡ 4. INSTALLATION DE NVM & NODE 20 (CRUCIAL POUR TON ZSHRC)..."
# Installation de NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Chargement immédiat de NVM pour l'utiliser dans ce script
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Installation de Node 20 (Demandé par ta fonction gemini)
echo "Installing Node 20..."
nvm install 20
nvm use 20
nvm alias default 20

# Installation de Gemini CLI sur cette version de Node
echo "Installing Gemini CLI..."
npm install -g @google/generative-ai-cli

echo "🐚 5. INSTALLATION OH MY ZSH & PLUGINS..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "📝 6. COPIE DE TES FICHIERS (On ne modifie rien, on copie juste)..."

# ZSHRC & P10K
[ -f "$BASE_DIR/zshrc" ] && cp -fv "$BASE_DIR/zshrc" "$HOME/.zshrc"
[ -f "$BASE_DIR/p10k.zsh" ] && cp -fv "$BASE_DIR/p10k.zsh" "$HOME/.p10k.zsh"

# RANGER
mkdir -p "$HOME/.config/ranger"
[ -f "$BASE_DIR/rc.conf" ] && cp -fv "$BASE_DIR/rc.conf" "$HOME/.config/ranger/rc.conf"
[ -f "$BASE_DIR/rifle.conf" ] && cp -fv "$BASE_DIR/rifle.conf" "$HOME/.config/ranger/rifle.conf"

# VS CODE (Settings + Extensions)
VSC_DIR="$HOME/.config/Code/User"
[ -d "$HOME/.var/app/org.visualstudio.code/config/Code/User" ] && VSC_DIR="$HOME/.var/app/org.visualstudio.code/config/Code/User"
mkdir -p "$VSC_DIR"
[ -f "$BASE_DIR/settings.json" ] && cp -fv "$BASE_DIR/settings.json" "$VSC_DIR/settings.json"

if [ -f "$BASE_DIR/extensions_vscode.zip" ]; then
    echo "📦 Extraction des extensions VS Code..."
    mkdir -p "$HOME/.vscode/extensions"
    unzip -o "$BASE_DIR/extensions_vscode.zip" -d "$HOME/.vscode/extensions"
fi

echo "💻 7. CONFIG TERMINAL GNOME..."
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
if [ -n "$PROFILE" ]; then
    SCHEMA="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"
    gsettings set "$SCHEMA" use-custom-font true
    gsettings set "$SCHEMA" font 'FiraCode Nerd Font Retina 12'
fi

echo "---"
echo "✅ TERMINÉ."
echo "👉 NVM et Node 20 sont installés : Ta fonction Gemini marchera."
echo "👉 Nerd Font installée : Ton thème P10K marchera."
echo "👉 VS Code restauré."

# On lance Zsh
exec zsh