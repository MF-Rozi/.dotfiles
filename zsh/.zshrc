# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="spaceship"
#ZSH_THEME="mf-rozi"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# custom commands / function

# Custom Spaceship section for RAM usage
spaceship_ram() {
  [[ $SPACESHIP_RAM_SHOW == false ]] && return

  local ram_used ram_total ram_percent
  if [[ -f /proc/meminfo ]]; then
    ram_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    ram_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    ram_used=$((ram_total - ram_available))
    ram_percent=$((ram_used * 100 / ram_total))
    
    ram_used_gb=$(awk "BEGIN {printf \"%.1f\", $ram_used/1024/1024}")
    ram_total_gb=$(awk "BEGIN {printf \"%.1f\", $ram_total/1024/1024}")
  else
    return
  fi

  spaceship::section \
    --color "$SPACESHIP_RAM_COLOR" \
    --prefix "$SPACESHIP_RAM_PREFIX" \
    --suffix "$SPACESHIP_RAM_SUFFIX" \
    --symbol "$SPACESHIP_RAM_SYMBOL" \
    "${ram_used_gb}/${ram_total_gb}GB (${ram_percent}%)"
}

# Spaceship RAM configuration
SPACESHIP_RAM_SHOW="${SPACESHIP_RAM_SHOW=true}"
SPACESHIP_RAM_PREFIX="${SPACESHIP_RAM_PREFIX=""}"
SPACESHIP_RAM_SUFFIX="${SPACESHIP_RAM_SUFFIX=" "}"
SPACESHIP_RAM_SYMBOL="${SPACESHIP_RAM_SYMBOL="🖥️ "}"
SPACESHIP_RAM_COLOR="${SPACESHIP_RAM_COLOR="yellow"}"


SPACESHIP_RPROMPT_ORDER=(
  ram
  time
)

SPACESHIP_USER_SHOW="always"
# SPACESHIP_PROMPT_ORDER=(
#   user          # Username
#   dir           # Current directory
#   git           # Git section
#   line_sep      # Line break
#   char          # Prompt character
# )




git-work(){
 GIT_SSH_COMMAND="ssh -i ~/Keys/github-work" git "$@"
}

mcconsole(){
    local password
    # -s: makes the input silent (no characters shown)
    read -s "password?Enter password for mfrozi@mc.mfrozi.xyz: "
  
    #newline
    echo 

  sshpass -p "$password" ssh -t mfrozi@mc.mfrozi.xyz  'screen -x mcserver'

}

alias docker="podman"

# export PATH=$PATH:/home/mfrozi/.spicetify
# export PATH="$HOME/.local/bin:/usr/lib/node_modules/corepack/shims:$HOME/.spicetify:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/lib/node_modules/corepack/shims:$PATH"
export PATH="$HOME/.spicetify:$PATH"

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/mfrozi/.dart-cli-completion/zsh-config.zsh ]] && . /home/mfrozi/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

# adding google chrome for flutter doctor
export CHROME_EXECUTABLE="/opt/google/chrome/google-chrome"

# add android platform-tools to path
export ANDROID_SDK_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_SDK_HOME/platform-tools:$PATH"


