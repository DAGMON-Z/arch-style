# 9. Neovim with LazyVim

**Neovim** is a keyboard-driven code editor. **LazyVim** is a ready-made Neovim
setup with file search, completion and syntax colors already configured.
(In this setup, autocomplete is turned off on purpose. See
[below](#autocomplete-is-off-on-purpose).)

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
| `lua/plugins/competitest.lua` | Receives problems from the browser and runs sample tests ([below](#get-problems-from-brave-competitive-companion)) |
| `templates/cp.cpp` | The starting code for every received problem |
| `lua/plugins/no-autocomplete.lua` | Turns off autocomplete popups, for practice ([below](#autocomplete-is-off-on-purpose)) |

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

To compile and run inside Neovim, press `` Ctrl + ` `` to open a terminal, then:

```bash
g++ -std=c++20 -O2 -Wall a.cpp -o a && ./a
```

## Competitive programming: compile, test, debug

### Autocomplete is off on purpose

**Autocomplete is turned off in this setup, to learn better.** Suggestions
don't pop up while you type, and no grey text guesses the rest of the line. In
contests and interviews you have to remember function names, headers and
syntax yourself, so practising without help builds that memory much faster.

What still works:

- **Error checking:** `clangd` still underlines mistakes, so you learn from them
  right away.
- **`Ctrl + Space`:** shows suggestions **on purpose**, when you're really
  stuck. Try to remember first!
- **`K`:** shows the documentation of the function under the cursor.

To turn autocomplete back on, delete
`~/.config/nvim/lua/plugins/no-autocomplete.lua` and restart Neovim.


### Get problems from Brave (Competitive Companion)

The fastest way: one click in the browser creates the `.cpp` file **and** all
the sample tests. Two pieces work together:

- **[Competitive Companion](https://chromewebstore.google.com/detail/competitive-companion/cjnmckjndlpiamhfimnnjmnckgghkjbl)**,
  a browser extension (Brave, Chrome, Firefox). It reads the problem page and
  sends the problem to your computer.
- **[competitest.nvim](https://github.com/xeluxee/competitest.nvim)**, a Neovim
  plugin (already in this setup). It receives the problem on port 27121, the
  port Competitive Companion sends to.

**One-time setup:** install Competitive Companion from the link above. A green
plus icon appears in Brave's toolbar. Pin it with the puzzle-piece menu so it's
always visible.

**For each problem:**

1. Open Neovim (`nvim`).
2. Press `Space C r` (receive problem). Neovim now waits for a problem.
3. In Brave, open the problem page (Codeforces, AtCoder, CSES, and many more)
   and click the green **+** icon.
4. Neovim shows where it will save the file. Press Enter to accept.
5. The file opens with the [template](#the-template), and the sample tests are
   saved next to it.

Files go to `~/cp/<site>/<contest>/<problem>.cpp`, for example
`~/cp/Codeforces/Round 1000/A. Example.cpp`. The tests are saved next to it as
`A. Example_input0.txt`, `A. Example_output0.txt`, and so on.

**Test your solution:** press `Space C t`. Neovim compiles with the judge's
flags (`-std=c++20 -O2 -Wall`), runs every sample test, and shows each one as
passed or failed, with your output next to the expected output. Press `q` to
close the results.

| Keys | Action |
| --- | --- |
| `Space C r` | Receive one problem from the browser |
| `Space C c` | Receive a whole contest (click the icon on the contest page) |
| `Space C t` | Compile and run all sample tests |
| `Space C a` | Add your own test |
| `Space C e` | Edit a test |
| `Space C d` | Delete a test |

> **CPH Submit**, another extension, only works with the CPH extension for VS
> Code. It isn't used with Neovim.

### The template

Every received problem starts from `~/.config/nvim/templates/cp.cpp`:

```cpp
#include <bits/stdc++.h>
using namespace std;

#define elgayar ios::sync_with_stdio(0); cin.tie(0); cout.tie(0)
#define endl '\n'

int main()
{
  elgayar;
  
}
```

- `#include <bits/stdc++.h>` includes the whole standard library at once.
- `#define` creates a shortcut: before compiling, the compiler replaces the
  name with the text after it.
- `elgayar` stands for the three fast input/output lines:
  `ios::sync_with_stdio(0)` stops `cin`/`cout` from syncing with C's
  `scanf`/`printf`, and `cin.tie(0)` and `cout.tie(0)` stop them from flushing
  each other before every read. Together they make reading big inputs much
  faster.
- `#define endl '\n'` makes `endl` print a plain newline. The real `endl` also
  *flushes* the output every time, which is slow when printing many lines.

Edit the file to change the starting code for future problems. Files you
already received keep their old code.

### Without the extension

The steps below work for any problem, even without Competitive Companion.

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

## VS Code shortcuts

`~/.config/nvim/lua/config/keymaps.lua` adds the main VS Code shortcuts, so
Neovim feels familiar. They work in normal mode, while typing, and on selected
text:

| Keys | Action |
| --- | --- |
| `Ctrl + Z` | Undo |
| `Ctrl + Shift + Z` or `Ctrl + Y` | Redo |
| `Ctrl + S` | Save |
| `Ctrl + A` | Select all |
| `Ctrl + C` / `Ctrl + X` / `Ctrl + V` | Copy / cut / paste (system clipboard). With nothing selected, copy and cut take the whole line |
| `Shift + arrows`, `Shift + Home/End` | Select text |
| `Alt + Up` / `Alt + Down` | Move the line (or selection) up / down |
| `Shift + Alt + Up` / `Down` | Copy the line (or selection) up / down |
| `Ctrl + /` | Comment / uncomment |
| `Ctrl + F` | Find (then `n` for the next match) |
| `Ctrl + Backspace` | Delete the previous word |
| `Tab` / `Shift + Tab` | Indent / unindent the selection |
| `` Ctrl + ` `` | Open / hide the terminal |

The Neovim keys still work as well. For example, `u` is undo, `Ctrl + R` is
redo, `y` copies and `p` pastes.

**Why `Ctrl + Z` needed fixing:** in a terminal, `Ctrl + Z` normally *pauses*
the running program and drops you back to the shell. If that ever happens (for
example in another program), type `fg` to bring the program back.

**kitty:** kitty uses `Ctrl + Shift + Z` for its own scrolling, so
`kitty.conf` frees it with `map kitty_mod+z`. Without that line, Neovim never
receives the key.

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
