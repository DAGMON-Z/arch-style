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
| `lua/config/options.lua` | Relative line numbers, and no reformatting when saving |
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

**The quick way:** press **`F6`**. It saves, compiles with the judge's flags
and runs your program in a terminal at the bottom. Type the input, and press
`Ctrl + D` when you've finished typing it. When the program ends, press any key
to close the terminal. `F6` also runs C, Java and Python files.

**By hand:** press `` Ctrl + ` `` to open a terminal, then:

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

### Saving doesn't change your code

LazyVim normally runs a **formatter** (`clang-format`) every time you save. It
rearranges your code into its own style: for example, it splits a long
`#define` over several lines with `\` at the ends, and moves `{` up next to
`int main()`. That's confusing while learning, so it's turned off with
`vim.g.autoformat = false` in `lua/config/options.lua`.

- **`Space c f`**: format the file on purpose, when you want it tidied.
- **`Space u f`**: turn format-on-save back on (or off) for now.


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

1. In the terminal, go to the folder for your problems and open Neovim there.
   It starts listening for problems by itself:

   ```bash
   mkdir -p ~/cp/sheet4 && cd ~/cp/sheet4 && nvim
   ```

   - `mkdir -p` creates the folder (and any missing parent folders). If it
     already exists, it does nothing.
   - `cd` goes into it, and `nvim` opens Neovim there.
   - `&&` runs the next command only if the one before it worked.

2. In Brave, open the problem page (Codeforces, AtCoder, CSES, and many more)
   and click the green **+** icon.
3. The file opens in Neovim with the [template](#the-template), and the sample
   tests are saved next to it. No keys and no questions.

Keep Neovim open and click **+** on the next problem: it opens too. On a contest
page, **+** sends the whole contest, and every problem gets its own file.

**Where the files go:** in the folder you opened Neovim in. If that folder isn't
meant for problems, Neovim asks where to save instead, and suggests
`~/cp/<site>/<contest>/`. Press Enter to accept, or type another path. These
count as "not for problems":

- your home folder itself (`~`), which is where Neovim starts if you open it
  from the app menu,
- hidden folders such as `~/.config` and `~/.local`, and everything inside them,
- the standard folders themselves: Desktop, Documents, Downloads, Music,
  Pictures, Videos, Public and Templates (folders *inside* them are fine),
- anything outside your home folder, such as `/tmp`.

> **Two Neovim windows open?** Only one program can listen on a port, so the
> first Neovim you opened receives the problems. If you close it, press
> `Space C r` in another one to make it listen. `Space C s` shows whether the
> current Neovim is listening.
>
> If a problem's file already exists, Neovim asks before replacing it, so your
> code is never overwritten by surprise.

Each problem is saved as `<problem>.cpp`, for example `A. Example.cpp`. The
tests are saved next to it as `A. Example_input0.txt`, `A. Example_output0.txt`,
and so on.

**Test your solution:** press **`F5`**, or `Space C t`. Neovim compiles with the judge's
flags (`-std=c++20 -O2 -Wall`), runs every sample test, and shows each one as
passed or failed, with your output next to the expected output. Press `q` to
close the results.

| Keys | Action |
| --- | --- |
| (nothing) | Problems and contests from the browser arrive by themselves |
| `Space C r` | Make this Neovim listen (only if another one was listening) |
| `Space C s` | Show whether this Neovim is listening |
| `F5` or `Space C t` | Save, compile and run all sample tests |
| `F6` | Save, compile and run normally: type the input yourself |
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

### Java

Java is installed for competitive programming (`jdk-openjdk`, the newest
version). Open a `.java` file and press **`F6`**: it compiles with `javac` and
runs it. Name the file after its class: `public class Main` goes in `Main.java`.

Check it's installed:

```bash
java -version
```

> **Already had Java from a version-numbered package**, such as
> `jdk25-openjdk`? The installer and update command install `jdk-openjdk`
> next to it, and that becomes your default Java. To keep only one, remove the
> old one afterwards:
>
> ```bash
> sudo pacman -Rns jdk25-openjdk
> ```
>
> - `-R` removes the package.
> - `n` also deletes its saved settings files, and `s` removes anything it
>   pulled in that nothing else needs.
>
> See which Java versions you have, and which one is the default, with
> `archlinux-java status`.

### PC2 contests

Many university and ICPC contests use **PC2** to submit solutions. Your team
gets a **kit** from the contest admin: a folder with `bin/` and `lib/` in it.
PC2 is a Java program. The kit asks for Java 17, but it also runs on the newest
Java that this setup installs, so you don't need a second Java.

**Setup (once per contest):**

1. Unzip the kit to `~/cp/PC2-team-contest`:

   ```bash
   mkdir -p ~/cp && unzip ~/Downloads/PC2-team-contest.zip -d ~/cp
   ```

   - `unzip <file> -d <folder>` extracts the zip into that folder.
   - Check that you now have `~/cp/PC2-team-contest/bin`. If the zip made an
     extra folder level, move things so `bin` and `lib` are directly inside
     `PC2-team-contest`.

2. Set the server address the admin gives you, in `bin/pc2v9.ini`:

   ```bash
   nvim ~/cp/PC2-team-contest/bin/pc2v9.ini
   ```

   Find the `server=` line, for example `server=192.168.1.30:50002`. Keep
   `:50002` at the end unless the admin says otherwise.

3. Connect to the contest Wi-Fi.

**Start PC2:** open the app launcher (click the Arch logo on the bar) and choose
**PC2 Team**, or type `pc2` in a terminal. Log in with the team name and
password from the admin.

The `pc2` command runs the long Java command from the kit's README for you. If
your kit is somewhere else, pass its folder:

```bash
pc2 ~/Desktop/PC2-team-contest
```

The kit's `.bat` files are for Windows. Ignore them.

PC2 looks sharp but a bit smaller than other apps on a 125% or 133% screen.
That's on purpose: Java can't scale by 1.33, and stretching it made it blurry.
See [troubleshooting](11-troubleshooting.md#java-apps-pc2-cant-run-on-wayland).

> **PC2 doesn't open?** Run `pc2` in a terminal to see its messages. "Contacting
> server" that never finishes means the computer can't reach the contest
> server: check the Wi-Fi and the address in `pc2v9.ini`. PC2 also writes logs
> in the kit's `bin/logs` folder.

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
| `Shift + arrows`, `Shift + Home/End` | Select text. You stay in typing mode: typing replaces the selection, and a plain arrow cancels it |
| `Alt + Up` / `Alt + Down` | Move the line (or selection) up / down |
| `Shift + Alt + Up` / `Down` | Copy the line (or selection) up / down |
| `Ctrl + /` | Comment / uncomment |
| `Ctrl + F` | Find (then `n` for the next match) |
| `Ctrl + Backspace` | Delete the previous word |
| `Tab` / `Shift + Tab` | Indent / unindent the selection |
| `` Ctrl + ` `` | Open / hide the terminal |
| `F5` | Save and run the sample tests (works while typing too) |
| `F6` | Save, compile and run the code normally, typing the input yourself |

The Neovim keys still work as well. For example, `u` is undo, `Ctrl + R` is
redo, `y` copies and `p` pastes.

**How `Shift + arrows` works:** `options.lua` sets `keymodel` and `selectmode`,
which turn on Neovim's **select mode**. It behaves like selecting in VS Code: the
bottom-left corner shows `SELECT`, typing replaces the selected text, and a
plain arrow key cancels the selection. (Neovim's other selection mode, *visual*
mode, uses `v`, and there typing runs commands instead.)

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
