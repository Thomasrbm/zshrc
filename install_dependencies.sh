#!/bin/bash

# --- SCRIPT D'INSTALLATION ULTIME (CORRIGÉ) ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
export NVM_DIR="$HOME/.nvm"

echo "🛑 1. NETTOYAGE PRÉALABLE..."
rm -rf "$HOME/.zshrc" "$HOME/.p10k.zsh" "$HOME/.oh-my-zsh" "$HOME/.nvm"
# On garde tes fichiers de config Ranger/VSCode mais on nettoie les caches
sudo apt-get remove --purge -y nodejs npm node-agent-base 2>/dev/null
sudo apt-get autoremove -y

echo "📦 2. INSTALLATION DES PAQUETS SYSTÈME..."
sudo apt update
sudo apt install -y zsh git curl unzip tree ranger eza fzf ripgrep btop build-essential

echo "🔡 3. INSTALLATION DES FONTS (CORRECTIF VISIBILITÉ)..."
mkdir -p ~/.local/share/fonts
# On installe Regular ET Retina pour éviter les textes invisibles
curl -fLo ~/.local/share/fonts/FiraCodeNerdFont-Regular.ttf https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf
curl -fLo ~/.local/share/fonts/FiraCodeNerdFont-Retina.ttf https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Retina/FiraCodeNerdFont-Retina.ttf
fc-cache -fv

echo "⚡ 4. NVM & NODE 20 (POUR GEMINI)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install 20
nvm use 20
nvm alias default 20
npm install -g @google/generative-ai-cli

echo "🐚 5. OH MY ZSH & PLUGINS (AVEC COMPLETIONS)..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Installation des 3 plugins requis par ton zshrc
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
# AJOUT CRUCIAL : Le plugin zsh-completions qui manquait
git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

echo "📝 6. COPIE DE TES CONFIGS..."
[ -f "$BASE_DIR/zshrc" ] && cp -fv "$BASE_DIR/zshrc" "$HOME/.zshrc"
[ -f "$BASE_DIR/p10k.zsh" ] && cp -fv "$BASE_DIR/p10k.zsh" "$HOME/.p10k.zsh"

mkdir -p "$HOME/.config/ranger"
[ -f "$BASE_DIR/rc.conf" ] && cp -fv "$BASE_DIR/rc.conf" "$HOME/.config/ranger/rc.conf"
[ -f "$BASE_DIR/rifle.conf" ] && cp -fv "$BASE_DIR/rifle.conf" "$HOME/.config/ranger/rifle.conf"

# VS Code : Copie + Sécurisation de la Font
VSC_DIR="$HOME/.config/Code/User"
mkdir -p "$VSC_DIR"
if [ -f "$BASE_DIR/settings.json" ]; then
    cp -fv "$BASE_DIR/settings.json" "$VSC_DIR/settings.json"
    # On ajoute ", monospace" pour que le texte soit toujours lisible même si la font charge mal
    sed -i 's/"editor.fontFamily": ".*"/"editor.fontFamily": "\x27FiraCode Nerd Font\x27, monospace"/' "$VSC_DIR/settings.json"
    sed -i 's/"terminal.integrated.fontFamily": ".*"/"terminal.integrated.fontFamily": "\x27FiraCode Nerd Font\x27, monospace"/' "$VSC_DIR/settings.json"
fi

if [ -f "$BASE_DIR/extensions_vscode.zip" ]; then
    mkdir -p "$HOME/.vscode/extensions"
    unzip -o "$BASE_DIR/extensions_vscode.zip" -d "$HOME/.vscode/extensions"
fi

echo "💻 7. FIX TERMINAL FONT..."
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
if [ -n "$PROFILE" ]; then
    SCHEMA="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"
    gsettings set "$SCHEMA" use-custom-font true
    gsettings set "$SCHEMA" font 'FiraCode Nerd Font 12'
fi

echo "✅ TOUT EST LÀ. Redémarre ton terminal."
exec zsh