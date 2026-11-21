# ~/.zshrc: settings for the zsh shell (the program that reads your commands)

# ---------- Basics ----------
export PATH="$HOME/.local/bin:$PATH"

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Command history: kept between sessions and shared between terminals
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups hist_ignore_space

# Tab completion, with a menu you can move through with the arrow keys
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# ---------- Normal keys ----------
# Emacs-style editing (the same basic keys as bash), then fix keys that zsh
# doesn't know by default: Home, End, Delete, Ctrl + arrows to jump words
bindkey -e
bindkey '^[[H' beginning-of-line     # Home
bindkey '^[[F' end-of-line           # End
bindkey '^[[1;5D' backward-word      # Ctrl + Left
bindkey '^[[1;5C' forward-word       # Ctrl + Right
bindkey '^H' backward-kill-word      # Ctrl + Backspace
bindkey '^[[3;5~' kill-word          # Ctrl + Delete

# ---------- VS Code style editing ----------
# Shift + arrows select text. Typing, Backspace or Delete replace the selection.
# Ctrl + A selects all. Ctrl + C copies the selection (or cancels, as usual,
# when nothing is selected). Ctrl + X cuts, Ctrl + V pastes.
# Ctrl + Z undoes and Ctrl + Shift + Z redoes.

# The selected text, wherever the selection started
_vs_selected_text() {
  local a=$MARK b=$CURSOR t
  (( a > b )) && { t=$a; a=$b; b=$t; }
  print -rn -- "${BUFFER[a+1,b]}"
}

# Shift + a movement key: start a selection if there isn't one, then move
_vs_select() { (( REGION_ACTIVE )) || zle set-mark-command; zle $1; }
# A movement key without Shift: drop the selection, then move
_vs_move() { REGION_ACTIVE=0; zle $1; }

for widget shift_key plain_keys in \
  backward-char     '^[[1;2D' '^[[D ^[OD' \
  forward-char      '^[[1;2C' '^[[C ^[OC' \
  beginning-of-line '^[[1;2H' '^[[H ^[OH' \
  end-of-line       '^[[1;2F' '^[[F ^[OF' \
  backward-word     '^[[1;6D' '^[[1;5D' \
  forward-word      '^[[1;6C' '^[[1;5C' \
  up-line           '^[[1;2A' '' \
  down-line         '^[[1;2B' ''; do
  eval "_vs_select_$widget() { _vs_select $widget; }"
  zle -N _vs_select_$widget
  bindkey "$shift_key" _vs_select_$widget
  if [[ -n $plain_keys ]]; then
    eval "_vs_move_$widget() { _vs_move $widget; }"
    zle -N _vs_move_$widget
    for key in ${=plain_keys}; do bindkey "$key" _vs_move_$widget; done
  fi
done

# Up / Down without Shift: drop the selection, then go through history as usual
_vs_history_up() { REGION_ACTIVE=0; zle up-line-or-history; }
_vs_history_down() { REGION_ACTIVE=0; zle down-line-or-history; }
zle -N _vs_history_up; zle -N _vs_history_down
bindkey '^[[A' _vs_history_up; bindkey '^[OA' _vs_history_up
bindkey '^[[B' _vs_history_down; bindkey '^[OB' _vs_history_down

# Typing replaces the selection
_vs_self_insert() { (( REGION_ACTIVE )) && zle kill-region; zle .self-insert; }
zle -N self-insert _vs_self_insert

# Backspace and Delete remove the selection, or one character as usual
_vs_backspace() { if (( REGION_ACTIVE )); then zle kill-region; else zle backward-delete-char; fi; }
_vs_delete() { if (( REGION_ACTIVE )); then zle kill-region; else zle delete-char; fi; }
zle -N _vs_backspace; zle -N _vs_delete
bindkey '^?' _vs_backspace
bindkey '^[[3~' _vs_delete

# Ctrl + A: select all
_vs_select_all() { MARK=0; CURSOR=${#BUFFER}; REGION_ACTIVE=1; }
zle -N _vs_select_all
bindkey '^A' _vs_select_all

# Ctrl + X: cut the selection to the clipboard (or the whole line, like VS Code)
_vs_cut() {
  (( REGION_ACTIVE )) || { MARK=0; CURSOR=${#BUFFER}; REGION_ACTIVE=1; }
  _vs_selected_text | wl-copy
  zle kill-region
}
zle -N _vs_cut
bindkey -rp '^X'          # remove zsh's own Ctrl+X shortcuts so Ctrl+X works at once
bindkey '^X' _vs_cut

# Ctrl + V: paste from the clipboard, replacing the selection
_vs_paste() {
  local text
  text=$(wl-paste --no-newline 2>/dev/null) || return
  (( REGION_ACTIVE )) && zle kill-region
  LBUFFER+=$text
}
zle -N _vs_paste
bindkey '^V' _vs_paste

# Ctrl + C: copy the selection. With nothing selected it cancels, as usual.
# Ctrl + C is sent as a signal, so it's caught here and passed to a widget.
_vs_copy_if_selected() {
  _vs_copied=0
  if (( REGION_ACTIVE )); then
    _vs_selected_text | wl-copy
    REGION_ACTIVE=0
    _vs_copied=1
  fi
}
zle -N _vs_copy_if_selected
TRAPINT() {
  if zle 2>/dev/null; then
    zle _vs_copy_if_selected
    (( _vs_copied )) && return 0
  fi
  return $(( 128 + $1 ))
}

# Ctrl + Z: undo. Ctrl + Shift + Z (and Ctrl + Y): redo.
# kitty sends Ctrl + Shift + Z as the code below (see kitty.conf).
bindkey '^Z' undo
bindkey '^[[122;6u' redo
bindkey '^Y' redo

# ---------- Prompt and system summary ----------
# Starship prompt, if it is installed
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# System summary in new kitty windows, but not inside Neovim's terminal.
# Wide window: with logo. Narrow: no logo. Very narrow: nothing.
if [[ -n $KITTY_WINDOW_ID && -z $NVIM ]] && command -v fastfetch >/dev/null 2>&1; then
  read -r _ term_columns < <(stty size 2>/dev/null)
  if (( ${term_columns:-0} >= 52 )); then
    fastfetch
  elif (( ${term_columns:-0} >= 32 )); then
    fastfetch --logo none
  fi
  unset term_columns
fi
