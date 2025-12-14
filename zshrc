# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
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



# LS/Filesystem Aliases (using eza)
alias ls='eza --git --icons --color=always'
alias ll='eza -al --header --git --icons --color=always'
alias la="tree"
alias duf="du -sh * | sort -rh" # Disk Usage Folder

# System and Utility Aliases
alias update="sudo apt update && sudo apt upgrade -y"
alias rel="source ~/.zshrc && echo Zsh config reloaded"
alias zsh="code ~/.zshrc"
alias py="python3"
alias serve="python3 -m http.server" # Simple HTTP server
alias open="explorer.exe ." # Useful for WSL
alias anti="antigravity ." # Preserve existing custom alias

# Custom Functions Aliases
alias extr="extract"

# --- Custom Functions ---
gemini() {
     nvm use 20 >/dev/null 2>&1
     command gemini "$@"
}



export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"



export LS_COLORS="${LS_COLORS}:*Makefile=01;31:*.js=01;33:*.ts=01;33:*.json=01;33:*.c=01;34:*.cpp=01;34:*.h=01;35:*.py=01;34"


# Fonction pour extraire n'importe quel type d'archive
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

# alias for git
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
setopt HIST_IGNORE_DUPS     # Don't record dupes
setopt HIST_SAVE_NO_DUPS    # Don't save dupes
setopt HIST_IGNORE_ALL_DUPS # Delete old recorded entry if new entry is a dupe
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when history is full
setopt HIST_FCNTL_LOCK      # Use fcntl lock on history file
setopt AUTO_CD

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- FZF Configuration ---
# Set up fzf key bindings and completions from the path you provided
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Use fd (if installed) for faster file finding
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Use eza for fzf previews
if command -v eza >/dev/null; then
  export FZF_CTRL_T_OPTS="--preview 'eza --git --icons --color=always {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --git --icons --color=always {}'"
fi

# --- Ranger Integration ---
# Function to integrate ranger with zsh
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

# Create a Zsh widget from the function
zle -N ranger-cd
# Bind ALT-r to the ranger-cd function
bindkey '^[r' ranger-cd

# Alias for convenience
alias r='ranger-cd'