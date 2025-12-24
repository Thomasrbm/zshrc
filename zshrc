# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

source $ZSH/oh-my-zsh.sh

# --- Custom Aliases ---
# Navigation
alias ..="cd .."
alias ...="cd ../.."

# LS/Filesystem Aliases (gestion intelligente eza/ls)
if command -v eza >/dev/null; then
    alias ls='eza --git --icons --color=always'
    alias ll='eza -al --header --git --icons --color=always'
else
    alias ls='ls --color=always'
    alias ll='ls -alF --color=always'
fi
alias la="tree"
alias duf="du -sh * | sort -rh"

# System and Utility Aliases
alias update="sudo apt update && sudo apt upgrade -y"
alias rel="source ~/.zshrc && echo Zsh config reloaded"
alias zsh="code ~/.zshrc"
alias py="python3"
alias serve="python3 -m http.server"
alias anti="python3 -c 'import antigravity'" 

# Custom Functions Aliases
alias extr="extract"

# --- Custom Functions ---
# ... (le début de ton fichier reste pareil)

# --- Custom Functions ---
gemini() {
     # On s'assure d'être sur Node 20
     export NVM_DIR="$HOME/.nvm"
     [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
     nvm use 20 >/dev/null 2>&1

     # On cherche le binaire
     if command -v gemini-chat >/dev/null; then
        gemini-chat "$@"
     else
        echo "⚠️  Commande 'gemini-chat' introuvable."
        echo "⏳  Installation automatique via npm..."
        npm install -g gemini-chat
        
        # On réessaie après install
        if command -v gemini-chat >/dev/null; then
            echo "✅  Installé ! Lancement..."
            gemini-chat "$@"
        else
            echo "❌  Echec de l'installation. Vérifie ta connexion."
        fi
     fi
}

# ... (la suite de ton fichier reste pareil)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

export LS_COLORS="${LS_COLORS}:*Makefile=01;31:*.js=01;33:*.ts=01;33:*.json=01;33:*.c=01;34:*.cpp=01;34:*.h=01;35:*.py=01;34"

# Fonction extract universelle
extract() {
    for f in "$@"; do
        if [ -f "$f" ]; then
            case "$f" in
                *.tar.bz2)   tar xjf "$f"     ;;
                *.tar.gz)    tar xzf "$f"     ;;
                *.bz2)       bunzip2 "$f"     ;;
                *.rar)       unrar x "$f"     ;;
                *.gz)        gunzip "$f"      ;;
                *.tar)       tar xf "$f"      ;;
                *.tbz2)      tar xjf "$f"     ;;
                *.tgz)       tar xzf "$f"     ;;
                *.zip)       unzip "$f"       ;;
                *.Z)         uncompress "$f"  ;;
                *.7z)        7z x "$f"        ;;
                *)           echo "'$f' ne peut pas être extrait via extract()" ;;
            esac
        else
            echo "'$f' n'est pas un fichier valide"
        fi
    done
}

# Git shortcuts
push() {
    git add .
    echo -n "Enter commit message: "
    read commit_message
    git commit -m "$commit_message"
    git push
}

commit() {
    git add .
    echo -n "Enter commit message: "
    read commit_message
    git commit -m "$commit_message"
}

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FCNTL_LOCK
setopt AUTO_CD

# FZF Loading
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- FZF Configuration ---
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
    source /usr/share/doc/fzf/examples/completion.zsh
fi

export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if command -v eza >/dev/null; then
  export FZF_CTRL_T_OPTS="--preview 'eza --git --icons --color=always {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --git --icons --color=always {}'"
fi

# --- Ranger Integration ---
ranger-cd() {
    local temp_file="$(mktemp -t "ranger_cd.XXXXXXXXXX")"
    ranger --choosedir="$temp_file" "${@:-.}"
    if [ -f "$temp_file" ]; then
        if [ "$(cat -- "$temp_file")" != "$(echo -n `pwd`)" ]; then
            cd -- "$(cat "$temp_file")"
        fi
        rm -f -- "$temp_file"
    fi
}

zle -N ranger-cd
bindkey '^[r' ranger-cd
alias r='ranger-cd'