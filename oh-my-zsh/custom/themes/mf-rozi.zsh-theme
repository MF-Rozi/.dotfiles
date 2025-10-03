# --- Custom Functions ---

# Function to get RAM usage (shows used/total)
# prompt_ram() {
#   # Uses the 'free' command and formats the output
#   echo -n "%F{cyan}🖥️ $(free -h | awk '/^Mem:/ {print $3 "/" $2}')%f"
# }
prompt_ram() {
  # Shows "Used/Total"
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
      # Only show if more than 0 seconds
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


# --- Prompt Definitions ---
precmd() {
  # Build the left side of the top line
  #local top_left="%F{magenta}%n%f on %W at %t $(git_prompt_info)"
  local top_left="%F{magenta}%n%f $(LC_TIME=C date +'%A at %-l:%M%p') $(git_prompt_info)"
  
  # # Build the right side of the top line
  # local top_right="$PROMPT_EXEC_TIME%F{green}_MEM: $(prompt_ram)%f"
  
  # Print the top line, using printf to right-align the second part
  # The \n at the end creates the newline for the two-line prompt
  printf "%s%*s\n" "${(%)top_left}" "$(($COLUMNS - ${#top_left} - ${#top_right}))" "${(%)top_right}"
}


# The PROMPT variable defines the bottom line where you type.
# PROMPT='%F{cyan}{%f %F{yellow}%~%f$(git_prompt_info) %F{cyan}}%f %# '
PROMPT='%F{cyan}{%f %F{yellow}%~%f %F{cyan}}%f %# '
# # Left-side prompt (PROMPT)
# # Format: username:hostname>~ >git setup
# PROMPT='%F{green}%n%f:%F{yellow}%m%f>%F{cyan}%~%f>$(git_prompt_info) '

# # Right-side prompt (RPROMPT)
# # Format: time-elapsed<datetime><ram>
# #RPROMPT='$PROMPT_ELAPSED%F{magenta}<%*><%f$(prompt_ram)%F{magenta}>%f'
RPROMPT='$PROMPT_EXEC_TIME%F{magenta}<%W>%f🖥️$(prompt_ram)%F{magenta}>%f'
