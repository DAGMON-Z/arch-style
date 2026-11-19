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
- `gdb`: the debugger (see below)

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

## Competitive programming: compile, test, debug

### 1. Put the sample input in a file

Copy the sample input from the problem into `in.txt`, next to your code:

```bash
nvim in.txt
```

### 2. Compile and run like the judge

```bash
g++ -std=c++20 -O2 -Wall a.cpp -o a && ./a < in.txt
```

- `g++` is the C++ compiler.
- `-std=c++20` uses the C++20 standard, which most judges support.
- `-O2` optimizes the program, like most judges do.
- `-Wall` shows warnings about suspicious code. Read them!
- `-o a` names the program `a`.
- `&&` runs the program only if compiling worked.
- `./a < in.txt` runs it, reading `in.txt` as if you typed it.

### 3. When the answer is wrong or it crashes: a debug build

```bash
g++ -std=c++20 -g -O0 -Wall -Wextra -fsanitize=address,undefined a.cpp -o a_dbg && ./a_dbg < in.txt
```

- `-g` keeps line numbers in the program, so errors point to your code.
- `-O0` turns optimization off, so the program runs exactly as written.
- `-Wextra` turns on even more warnings.
- `-fsanitize=address,undefined` adds checks that stop the program at the exact
  line of common bugs: reading outside an array, using freed memory, integer
  overflow, and more.

For example, a loop that goes one step too far, `for (int i = 0; i <= n; i++)`,
stops with a message like this instead of giving a random wrong answer:

```text
Assertion '__n < this->size()' failed.
```

That means "an index was not smaller than the vector's size".

The debug build is slower, so use it to find bugs, not to submit.

### 4. Step through the code with gdb

`gdb` lets you pause the program and look at your variables:

```bash
g++ -std=c++20 -g -O0 a.cpp -o a_gdb
gdb ./a_gdb
```

Then type these commands at the `(gdb)` prompt:

| Command | What it does |
| --- | --- |
| `break 10` | Pause when the program reaches line 10 |
| `run < in.txt` | Start the program, reading `in.txt` as input |
| `next` (or `n`) | Run the current line, then pause again |
| `step` (or `s`) | Like `next`, but go *into* a function call |
| `print sum` (or `p sum`) | Show a variable. Works on vectors too: `p a` |
| `info locals` | Show all variables in the current function |
| `continue` (or `c`) | Run until the next pause point |
| `bt` | After a crash: show which functions led there |
| `quit` (or `q`) | Leave gdb |

Example session:

```text
(gdb) break 10
(gdb) run < in.txt
Breakpoint 1, main () at a.cpp:10
(gdb) p a
$1 = std::vector of length 3, capacity 3 = {1, 2, 3}
(gdb) next
(gdb) p sum
$2 = 6
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
