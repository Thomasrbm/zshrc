#!/bin/bash
set -euo pipefail

# --- SCRIPT FINAL (OFFICIAL GEMINI + DOCKER + 42 TOOLS) ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
export NVM_DIR="$HOME/.nvm"

# --- VÉRIFICATION SUDO (OBLIGATOIRE) ---
if [ "$EUID" -eq 0 ]; then
    echo "❌ ERREUR : Ne lance PAS ce script en root (sudo ./install_dependencies.sh)."
    echo "   Lance-le en utilisateur normal : ./install_dependencies.sh"
    echo "   Le script appellera sudo lui-même quand nécessaire."
    exit 1
fi

if ! sudo -v; then
    echo ""
    echo "❌ ERREUR : Ce script nécessite les droits sudo (pour apt install)."
    echo "   ➜  Relance-le et tape ton mot de passe quand demandé :"
    echo "      ./install_dependencies.sh"
    exit 1
fi

# Garde la session sudo active pendant toute la durée du script
( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

echo "📍 Installation propre et définitive..."

echo "🛑 1. NETTOYAGE..."
rm -rf "$HOME/.oh-my-zsh" "$HOME/.config/Code" "$HOME/.vscode"
rm -f "$HOME/.zshrc" "$HOME/.p10k.zsh"

echo "📦 2. INSTALLATION SYSTÈME..."
sudo apt update

# Paquets indispensables — échec = on stoppe
sudo apt install -y zsh git curl unzip tree ranger fzf ripgrep build-essential libssl-dev python3-pip

# Paquets optionnels — on tente un par un, échec d'un = on continue
for pkg in btop eza bat i3 ncdu tldr; do
    if sudo apt install -y "$pkg" 2>/dev/null; then
        echo "  ✓ $pkg"
    else
        echo "  ⚠ $pkg non disponible sur ce système, skip."
    fi
done

# --- FIX LAZYGIT (Binaire) ---
echo "🐙 INSTALLATION LAZYGIT..."
cd /tmp
LAZYGIT_VERSION="0.44.1"
curl -L -o lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
if file lazygit.tar.gz | grep -q "gzip compressed data"; then
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit
else
    echo "❌ Erreur Lazygit. On continue."
fi

echo "🔡 3. INSTALLATION FONTS..."
wget -O FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
unzip -o -q FiraCode.zip -d ~/.local/share/fonts
rm FiraCode.zip
fc-cache -fv

echo "⚡ 4. NODEJS..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 20
nvm use 20
nvm alias default 20

if command -v claude >/dev/null; then
    echo "🤖 Claude Code déjà installé ($(command -v claude)), skip."
else
    echo "🤖 Installation de Claude Code (officiel Anthropic)..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

echo "🐚 5. INSTALLATION OH MY ZSH..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

# --- TON ZSHRC CORRIGÉ ---
echo "📝 6. GÉNÉRATION .ZSHRC..."
cat << 'EOF' > "$HOME/.zshrc"
# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

source $ZSH/oh-my-zsh.sh

# --- Aliases ---
alias ..="cd .."
alias ...="cd ../.."
if command -v eza >/dev/null; then
    alias ls='eza --git --icons --color=always'
    alias ll='eza -al --header --git --icons --color=always'
else
    alias ls='ls --color=always'
    alias ll='ls -alF --color=always'
fi
alias la="tree"
alias duf="du -sh * | sort -rh"
alias update="sudo apt update && sudo apt upgrade -y"
alias rel="source ~/.zshrc && echo Zsh config reloaded"
alias zsh="code ~/.zshrc"
alias py="python3"
alias serve="python3 -m http.server"
alias anti="python3 -c 'import antigravity'" 
alias extr="extract"
alias r='ranger-cd'

# --- Claude Code Function ---
claude() {
     # Charge NVM si besoin
     export NVM_DIR="$HOME/.nvm"
     [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
     nvm use 20 >/dev/null 2>&1

     # Ajoute le chemin d'install par défaut de Claude Code au PATH si besoin
     export PATH="$HOME/.local/bin:$PATH"

     if command -v claude >/dev/null; then
        command claude "$@"
     else
        echo "⚠️ Commande 'claude' introuvable. Installation..."
        curl -fsSL https://claude.ai/install.sh | bash
        command claude "$@"
     fi
}

# --- Extract ---
extract() {
    for f in "$@"; do
        if [ -f "$f" ]; then
            case "$f" in
                *.tar.bz2)   tar xjf "$f"     ;;
                *.tar.gz)    tar xzf "$f"     ;;
                *.rar)       unrar x "$f"     ;;
                *.zip)       unzip "$f"       ;;
                *)           echo "'$f' erreur extraction" ;;
            esac
        fi
    done
}

# --- Git Shortcuts ---
push() {
    git add .
    echo -n "Message: "
    read msg
    git commit -m "$msg"
    git push
}

# --- Configs ---
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Ranger
ranger-cd() {
    local temp_file="$(mktemp -t "ranger_cd.XXXXXXXXXX")"
    ranger --choosedir="$temp_file" "${@:-.}"
    if [ -f "$temp_file" ] && [ "$(cat -- "$temp_file")" != "$(pwd)" ]; then
        cd -- "$(cat "$temp_file")"
    fi
    rm -f -- "$temp_file"
}
zle -N ranger-cd
bindkey '^[r' ranger-cd
EOF

# Copie des configs locales si présentes (set -e safe)
[ -f "$BASE_DIR/p10k.zsh" ]   && cp -v "$BASE_DIR/p10k.zsh"   "$HOME/.p10k.zsh"          || true
mkdir -p "$HOME/.config/ranger"
[ -f "$BASE_DIR/rc.conf" ]    && cp -v "$BASE_DIR/rc.conf"    "$HOME/.config/ranger/rc.conf"    || true
[ -f "$BASE_DIR/rifle.conf" ] && cp -v "$BASE_DIR/rifle.conf" "$HOME/.config/ranger/rifle.conf" || true

echo "⚙️ 7. CONFIGURATION VS CODE..."
VSC_DIR="$HOME/.config/Code/User"
mkdir -p "$VSC_DIR"

echo '{
    "workbench.colorTheme": "GitHub Dark Dimmed",
    "files.autoSave": "afterDelay",
    "editor.fontFamily": "FiraCode Nerd Font",
    "terminal.integrated.fontFamily": "FiraCode Nerd Font Mono",
    "terminal.integrated.customGlyphs": true,
    "editor.fontLigatures": true,
    "editor.fontSize": 14,
    "terminal.integrated.defaultProfile.linux": "zsh",
    "terminal.integrated.profiles.linux": {
        "zsh": {
            "path": "/usr/bin/zsh",
            "args": ["-l"]
        }
    },
    "[cpp]": { "editor.defaultFormatter": "keyhr.42-c-format" }
}' > "$VSC_DIR/settings.json"

if command -v code >/dev/null; then
    echo "🧩 Extensions (Docker, 42, etc)..."
    for ext in \
        "mhutchie.git-graph" \
        "GitHub.github-vscode-theme" \
        "pkief.material-icon-theme" \
        "usernamehw.errorlens" \
        "keyhr.42-c-format" \
        "wblech.42-ft-count-line" \
        "ms-azuretools.vscode-docker" \
        "ms-vscode-remote.remote-containers"; do
        code --install-extension "$ext" --force || echo "  ⚠ extension $ext échouée, skip."
    done
fi

echo "✅ FINI. Redémarre ton terminal."
exec zsh