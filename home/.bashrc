#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"

# Starship prompt, if it is installed
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# System summary in new kitty windows, but not inside Neovim's terminal.
# Wide window: with logo. Narrow: no logo. Very narrow: nothing.
if [[ -n $KITTY_WINDOW_ID && -z $NVIM ]] && command -v fastfetch >/dev/null 2>&1; then
    read -r _ term_columns < <(stty size 2>/dev/null)
    if ((${term_columns:-0} >= 52)); then
        fastfetch
    elif ((${term_columns:-0} >= 32)); then
        fastfetch --logo none
    fi
    unset term_columns
fi
