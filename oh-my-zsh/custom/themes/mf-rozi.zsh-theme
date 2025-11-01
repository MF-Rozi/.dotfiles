# --- Custom Functions ---

# Function to get RAM usage (shows used/total)
prompt_ram() {
  echo -n "$(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
}

# Timer functions to calculate command execution time
prompt_timer_start() {
  timer=${timer:-$SECONDS}
}
prompt_timer_stop() {
  if [ $timer ]; then
    elapsed=$((SECONDS - timer))
    if [ $elapsed -gt 0 ]; then
      PROMPT_EXEC_TIME="%F{green}${elapsed}s%f "
    else
      PROMPT_EXEC_TIME=""
    fi
    unset timer
  fi
}

# Add timer functions to Zsh's hooks
add-zsh-hook preexec prompt_timer_start
add-zsh-hook precmd prompt_timer_stop


# --- Git Status Configuration ---
# Customize the appearance of the git info
ZSH_THEME_GIT_PROMPT_PREFIX="%F{blue} git:(%f"
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{blue})%f"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{red}*%f"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{green}✔%f"

# Get git info for the prompt
git_information(){
  local git_info=""
  if git rev-parse --git-dir > /dev/null 2>&1; then
    local branch=$(git branch --show-current 2>/dev/null)
    if [[ -n $branch ]]; then
      if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
        git_info="${ZSH_THEME_GIT_PROMPT_PREFIX}${branch}${ZSH_THEME_GIT_PROMPT_CLEAN}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
      else
        git_info="${ZSH_THEME_GIT_PROMPT_PREFIX}${branch}${ZSH_THEME_GIT_PROMPT_DIRTY}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
      fi
    fi
  fi
  echo -n "$git_info"
}

# --- Prompt Definitions ---
precmd() { 
 local git_info="$(git_information)"
  local top_left="%F{magenta}%n%f $(LC_TIME=C date +'%A at %-l:%M%p')${git_info}"
  printf "%s\n" "${(%)top_left}"
}

PROMPT='%F{cyan}{%f %F{yellow}%~%f %F{cyan}}%f %# '

RPROMPT='$PROMPT_EXEC_TIME%F{magenta}<%W> %f🖥️$(prompt_ram)%F{magenta}%f'
