# zsh configuration rc file. 
# Ido Haber // ihaber@wisc.edu
# December 30, 2024

# ============================
# Homebrew Setup (must be first)
# ============================
# Initialize Homebrew - check both possible locations
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ============================
# PATH Configuration
# ============================
export PATH="$HOME/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:/Users/idohaber/.my_scripts/"
export PATH="$HOME/.local/bin:$PATH"

# ============================
# Environment Variables
# ============================
export SKETCHY_DIR="$HOME/.config/sketchybar/"

# matlab
export DYLD_LIBRARY_PATH=/Applications/MATLAB/MATLAB_Runtime/R2024a/runtime/maca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/bin/maca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/sys/osmaca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/extern/bin/maca64:$DYLD_LIBRARY_PATH

# Docker variables
if command -v brew &> /dev/null; then
  export PATH="$(brew --prefix)/opt/qt5/bin:$PATH"
fi
export DOCKER_HOST_IP=host.docker.internal
export DISPLAY=host.docker.internal:0

# Whoop API credentials (get from https://developer.whoop.com)
# Set these in your shell or add them here:
# export WHOOP_CLIENT_ID="your_client_id"
# export WHOOP_CLIENT_SECRET="your_client_secret"

# ============================
# Oh My Zsh Configuration
# ============================
# Note: Oh My Zsh will set up plugins, themes, and some default settings
# Custom settings below will override oh-my-zsh defaults
if [ -d "$HOME/oh-my-zsh" ]; then
  export ZSH="$HOME/oh-my-zsh"
  
  # Oh My Zsh settings (set before sourcing)
  ENABLE_CORRECTION="true"
  COMPLETION_WAITING_DOTS="true"
  
  # Oh My Zsh plugins
  plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search aliases)
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#d79921'
  
  # Source oh-my-zsh (this will load plugins and set default theme)
  source "$ZSH/oh-my-zsh.sh"
else
  echo "Warning: Oh My Zsh not found at $HOME/oh-my-zsh. Some features may not work."
fi

# ============================
# Custom Aliases (override oh-my-zsh defaults)
# ============================
alias zshconfig="mate ~/.zshrc"
alias vi='nvim'
alias t=tmux
alias mp="cd ~/Git-Projects/"
alias ms="cd ~/Applications/SimNIBS-4.5/"
alias md="cd ~/.dotfiles/"
alias mn="cd ~/.dotfiles/nvim/.config/nvim/ && vi ."
alias mo="cd ~/Silicon_Mind/"
alias matme='/Applications/MATLAB_R2024a.app/bin/matlab  -nodisplay -nosplash'

# ============================
# Custom Functions
# ============================
stam () {
  name=${1:-$(date "+%Y-%m-%d_%H-%M-%S")}
  mkdir -p "$HOME/sandbox/$name" &&
  cd "$HOME/sandbox/$name" &&
  vi .
}

# ============================
# Tool Initializations
# ============================
# Load atuin environment if installed
if [ -f "$HOME/.atuin/bin/env" ]; then
  . "$HOME/.atuin/bin/env"
fi

# Initialize zoxide if available
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# Initialize atuin if available
if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh)"
fi

# Initialize direnv if available
if command -v direnv &> /dev/null; then
  eval "$(direnv hook zsh)"
fi

# ============================
# Custom Keybindings (override oh-my-zsh defaults)
# ============================
bindkey -v  # Enable VI mode

# ============================
# Custom Prompt (override oh-my-zsh theme)
# ============================
# This must be at the end to override oh-my-zsh's prompt
setopt PROMPT_SUBST
PROMPT='%n|%1~$(git rev-parse --git-dir > /dev/null 2>&1 && echo " ($(git branch --show-current 2>/dev/null))") > '

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/idohaber/.lmstudio/bin"
# End of LM Studio CLI section


# opencode
export PATH=/Users/idohaber/.opencode/bin:$PATH
