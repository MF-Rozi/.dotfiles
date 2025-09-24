# --- Custom Functions ---

# Function to get RAM usage (shows used/total)
prompt_ram() {
  # Uses the 'free' command and formats the output
  echo -n "%F{cyan}🖥️ $(free -h | awk '/^Mem:/ {print $3 "/" $2}')%f"
}

# Function to track command execution time
preexec() {
  timer=${timer:-$SECONDS}
}
precmd() {
  if [ $timer ]; then
    elapsed=$((SECONDS - timer))
    if [ $elapsed -gt 0 ]; then
      # Only show if elapsed time is greater than 0
      PROMPT_ELAPSED="%F{yellow}[${elapsed}s]%f"
    else
      PROMPT_ELAPSED=""
    fi
    unset timer
  fi
}


# --- Git Status Configuration ---
# Customize the appearance of the git info
ZSH_THEME_GIT_PROMPT_PREFIX="%F{blue} git:(%f"
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{blue})%f"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{red}*%f"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{green}✔%f"


# --- Prompt Definitions ---

# Left-side prompt (PROMPT)
# Format: username:hostname>~ >git setup
PROMPT='%F{green}%n%f:%F{yellow}%m%f>%F{cyan}%~%f>$(git_prompt_info) '

# Right-side prompt (RPROMPT)
# Format: time-elapsed<datetime><ram>
#RPROMPT='$PROMPT_ELAPSED%F{magenta}<%*><%f$(prompt_ram)%F{magenta}>%f'
RPROMPT='$PROMPT_ELAPSED%F{magenta}<%*><%f$(prompt_ram)%F{magenta}>%f'
