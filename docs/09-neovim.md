# 9. Neovim with LazyVim

**Neovim** is a keyboard-driven code editor. **LazyVim** is a ready-made Neovim
setup with file search, completion and syntax colors already configured.

Config: `~/.config/nvim/` (started from the
[LazyVim starter](https://github.com/LazyVim/starter))

## My changes to the starter

| File | Change |
| --- | --- |
| `lua/config/lazy.lua` | Turns on LazyVim's clangd extra for C and C++ |
| `lua/config/options.lua` | Relative line numbers |
| `lua/plugins/colorscheme.lua` | tokyonight, "night" style |
| `lua/plugins/cpp.lua` | Uses the system `clangd` instead of downloading another copy |
| `~/.config/clangd/config.yaml` | Treats single `.cpp` files as C++20 |

## First start

The first time you run `nvim`, it downloads its plugins. That needs internet and
takes a minute. It also needs these packages, which `install.sh` installs:

- `git`: downloads plugins
- `tree-sitter-cli` and `gcc`: build the parsers for syntax colors
- `unzip`: unpacks tools that LazyVim's tool installer, Mason, downloads
- `ripgrep`, `fd` and `fzf`: fast searching
- `clang`: provides `clangd`, the C++ language server

## C++ for competitive programming

`#include <bits/stdc++.h>` works because `clangd` uses GCC's standard library
headers. `~/.config/clangd/config.yaml` adds `-std=c++20` for single files, so
there's no project setup.

Try it:

```bash
mkdir -p ~/cp && cd ~/cp && nvim a.cpp
```

To compile and run inside Neovim, press `Space f t` to open a terminal, then:

```bash
g++ -std=c++20 -O2 -Wall a.cpp -o a && ./a
```

## Survival keys

| Keys | Action |
| --- | --- |
| `i` | Start typing |
| `Esc` | Stop typing |
| `:w` | Save |
| `:q` | Quit (`:q!` quits without saving) |
| `Space` (then wait) | Menu of commands |
| `Space Space` | Find a file |
| `Space s g` | Search text in all files |
| `g d` | Go to definition |
| `K` | Show documentation |
| `Space u h` | Toggle the gray hints in code |

Relative line numbers show how far each line is from the cursor, so `5j` jumps
down exactly to the line marked 5.
