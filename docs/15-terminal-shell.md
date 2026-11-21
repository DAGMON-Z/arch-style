# 15. The terminal shell: zsh with VS Code keys

The **shell** is the program that reads the commands you type in the terminal.
Arch starts with **bash**. This setup uses **zsh** instead, because it can edit
the command line like a text editor: select, copy, cut, paste, undo and **redo**.
bash has no redo, and can't replace a selection when you type.

Commands work the same in both. Config: `~/.zshrc` (your old `~/.bashrc` stays
too, in case you switch back).

## Keys

| Keys | What it does |
| --- | --- |
| `Shift + arrows` | Select text |
| `Shift + Home` / `Shift + End` | Select to the start / end of the line |
| `Ctrl + Shift + Left` / `Right` | Select a word at a time |
| typing | Replaces the selection |
| `Backspace` / `Delete` | Remove the selection (or one character) |
| `Ctrl + A` | Select all |
| `Ctrl + C` | **Copy** the selection. With nothing selected, it **cancels** the line or a running program, as usual |
| `Ctrl + X` | Cut the selection (or the whole line) |
| `Ctrl + V` | Paste, replacing the selection |
| `Ctrl + Z` | Undo |
| `Ctrl + Shift + Z` or `Ctrl + Y` | Redo |
| `Ctrl + Left` / `Ctrl + Right` | Jump a word |
| `Ctrl + Backspace` | Delete the previous word |
| `Ctrl + [` / `Ctrl + ]` | Go to the beginning / end of the line |
| `Up` / `Down` | Previous / next command from history |
| `Tab` | Complete a command or file name (press again for a menu) |

Copy, cut and paste use the **system clipboard**, so you can paste into Brave,
Discord or Neovim, and the other way around.

Undo goes back one character at a time.

### Ctrl + Z and running programs

At the prompt, `Ctrl + Z` is undo. While a program is running, `Ctrl + Z` still
does its usual terminal job: it **pauses** the program and gives you the prompt
back. Type `fg` to continue the paused program. To stop a program, use
`Ctrl + C`.

### Why kitty is involved

kitty normally uses `Ctrl + Shift + Z` to scroll to the previous prompt. In
`kitty.conf`, this line makes it send the key to the program instead, as a code
that both zsh and Neovim recognize:

```
map ctrl+shift+z send_text all \x1b[122;6u
```

## How it works

The keys are small **widgets** (zsh's name for editing functions) in
`~/.zshrc`. For example, `Ctrl + A` sets the start of the selection (`MARK`) to
the beginning of the line and the cursor to the end:

```zsh
_vs_select_all() { MARK=0; CURSOR=${#BUFFER}; REGION_ACTIVE=1; }
zle -N _vs_select_all      # register it as a widget
bindkey '^A' _vs_select_all  # connect it to Ctrl + A
```

- `BUFFER` is the text you've typed, `CURSOR` is where the cursor is.
- `REGION_ACTIVE=1` means "show and use the selection".
- `bindkey` connects a key to a widget. `^A` means `Ctrl + A`.

`Ctrl + C` is special: the terminal turns it into a *signal* rather than a key.
`~/.zshrc` catches that signal with a function called `TRAPINT`. If text is
selected it copies it, and otherwise it lets the signal cancel as usual.

**`Ctrl + [`** is normally sent exactly like `Esc`, so programs can't tell the
two apart. kitty sends it as a different code (`map ctrl+[ ...` in
`kitty.conf`), and `~/.zshrc` and Neovim treat that code as "beginning of the
line". The `Esc` key itself works as before.

## Switching shells

**To zsh:** the installer offers this, and so does the
[update command](00-start-here.md#part-8-getting-updates) if you're still on
bash. Or switch yourself:

```bash
chsh -s /usr/bin/zsh
```

`chsh` ("change shell") sets the shell that new terminals start. It asks for
your password. Then log out and back in, so every program sees the change.

> **Still bash after updating?** Getting `~/.zshrc` doesn't switch your shell
> by itself, so the VS Code keys don't work in bash. Run the `chsh` command
> above (or the update command and answer **y**), then log out and back in.

**Back to bash:** `chsh -s /usr/bin/bash`, then log out and back in.

Check which shell you're using: `echo $SHELL`.
