#!/bin/bash

# --- SCRIPT FINAL (OFFICIAL GEMINI + DOCKER + 42 TOOLS) ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
export NVM_DIR="$HOME/.nvm"

echo "📍 Installation propre et définitive..."

echo "🛑 1. NETTOYAGE..."
rm -rf "$HOME/.oh-my-zsh" "$HOME/.config/Code" "$HOME/.vscode"
rm -f "$HOME/.zshrc" "$HOME/.p10k.zsh"

echo "📦 2. INSTALLATION SYSTÈME..."
sudo apt update
sudo apt install -y zsh git curl unzip tree ranger fzf ripgrep btop build-essential libssl-dev python3-pip eza bat i3 ncdu tldr

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

echo "⚡ 4. NODEJS & GEMINI OFFICIEL..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 20
nvm use 20
nvm alias default 20

echo "🤖 Installation du CLI Gemini Officiel..."
# C'est LE paquet officiel de Google. Il fournit la commande 'gemini'.
npm install -g @google/gemini-cli

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

# --- Gemini Function ---
gemini() {
     # Charge NVM si besoin
     export NVM_DIR="$HOME/.nvm"
     [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
     nvm use 20 >/dev/null 2>&1
     
     if command -v gemini >/dev/null; then
        command gemini "$@"
     else
        echo "⚠️ Commande 'gemini' introuvable. Installation..."
        npm install -g @google/gemini-cli
        command gemini "$@"
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

# Copie des configs locales si présentes
[ -f "$BASE_DIR/p10k.zsh" ] && cp -v "$BASE_DIR/p10k.zsh" "$HOME/.p10k.zsh"
mkdir -p "$HOME/.config/ranger"
[ -f "$BASE_DIR/rc.conf" ] && cp -v "$BASE_DIR/rc.conf" "$HOME/.config/ranger/rc.conf"
[ -f "$BASE_DIR/rifle.conf" ] && cp -v "$BASE_DIR/rifle.conf" "$HOME/.config/ranger/rifle.conf"

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
    "[cpp]": { "editor.defaultFormatter": "keyhr.42-c-format" }
}' > "$VSC_DIR/settings.json"

if command -v code >/dev/null; then
    echo "🧩 Extensions (Docker, 42, etc)..."
    code --install-extension "mhutchie.git-graph" --force
    code --install-extension "GitHub.github-vscode-theme" --force
    code --install-extension "pkief.material-icon-theme" --force
    code --install-extension "usernamehw.errorlens" --force
    code --install-extension "keyhr.42-c-format" --force
    code --install-extension wblech.42-ft-count-line --force
    code --install-extension "ms-azuretools.vscode-docker" --force
    code --install-extension "ms-vscode-remote.remote-containers" --force
fi

echo "✅ FINI. Redémarre ton terminal."
exec zsh