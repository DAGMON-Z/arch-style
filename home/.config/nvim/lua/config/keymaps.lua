-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- VS Code style shortcuts, so Neovim feels familiar.
-- The normal Neovim keys still work too (u = undo, Ctrl+R = redo, y = copy...).
-- Modes: "n" normal, "i" typing (insert), "v" selection (visual).
local map = vim.keymap.set

-- Undo / redo. Ctrl+Z would otherwise pause Neovim and drop you to the shell.
-- Save with Ctrl+S while typing, and keep typing (LazyVim's version pressed Esc)
map("i", "<C-s>", "<Cmd>write<CR>", { desc = "Save File" })

map("n", "<C-z>", "u", { desc = "Undo" })
map("i", "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })
map("v", "<C-z>", "<Esc>u", { desc = "Undo" })
map({ "n", "i" }, "<C-S-z>", "<Cmd>redo<CR>", { desc = "Redo" })
map({ "n", "i" }, "<C-y>", "<Cmd>redo<CR>", { desc = "Redo" })

-- Select all. <C-g> switches to Select mode, so typing replaces everything.
map({ "n", "i", "v" }, "<C-a>", "<Esc>ggVG<C-g>", { desc = "Select all" })

-- Copy / cut / paste with the system clipboard (the "+ register).
-- With nothing selected, copy and cut take the whole line, like VS Code.
map("v", "<C-c>", '"+y', { desc = "Copy" })
map("n", "<C-c>", '"+yy', { desc = "Copy line" })
map("v", "<C-x>", '"+d', { desc = "Cut" })
map("n", "<C-x>", '"+dd', { desc = "Cut line" })
map("n", "<C-v>", '"+P', { desc = "Paste" })
map("v", "<C-v>", '"_d"+P', { desc = "Paste over selection" })
map("i", "<C-v>", "<C-r><C-o>+", { desc = "Paste" })

-- Select with Shift + arrows: handled by the keymodel and selectmode settings
-- in options.lua, which work like VS Code (typing replaces the selection).

-- Move lines with Alt + Up/Down
map("n", "<A-Up>", "<A-k>", { remap = true, desc = "Move line up" })
map("n", "<A-Down>", "<A-j>", { remap = true, desc = "Move line down" })
map("i", "<A-Up>", "<Esc><A-k>gi", { remap = true, desc = "Move line up" })
map("i", "<A-Down>", "<Esc><A-j>gi", { remap = true, desc = "Move line down" })
map("v", "<A-Up>", "<A-k>", { remap = true, desc = "Move selection up" })
map("v", "<A-Down>", "<A-j>", { remap = true, desc = "Move selection down" })

-- Copy the line up/down with Shift + Alt + Up/Down
map("n", "<S-A-Down>", "<Cmd>t.<CR>", { desc = "Copy line down" })
map("n", "<S-A-Up>", "<Cmd>t-1<CR>", { desc = "Copy line up" })
map("i", "<S-A-Down>", "<Cmd>t.<CR>", { desc = "Copy line down" })
map("i", "<S-A-Up>", "<Cmd>t-1<CR>", { desc = "Copy line up" })
map("v", "<S-A-Down>", ":t'><CR>gv", { silent = true, desc = "Copy selection down" })
map("v", "<S-A-Up>", ":t'<-1<CR>gv", { silent = true, desc = "Copy selection up" })

-- Comment / uncomment with Ctrl + /
map("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
map("v", "<C-/>", "gcgv", { remap = true, desc = "Toggle comment" })
map("i", "<C-/>", "<Esc>gcca", { remap = true, desc = "Toggle comment" })

-- Terminal with Ctrl + ` (like VS Code), since Ctrl + / is now comment
map({ "n", "t" }, "<C-`>", function()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end, { desc = "Toggle terminal" })

-- Run the sample tests with F5: save, then run (works while typing too)
map({ "n", "i", "v" }, "<F5>", function()
  require("stay_insert").pause() -- back to typing after closing the results
  vim.cmd("stopinsert")
  vim.cmd("silent! write")
  vim.cmd("CompetiTest run")
end, { desc = "Save and run sample tests" })

-- Run the code normally with F6: save, compile, and run it in a terminal where
-- you type the input yourself. Press any key at the end to close the terminal.
local function run_command()
  local file = vim.fn.expand("%:t")     -- name.cpp
  local name = vim.fn.expand("%:t:r")   -- name
  local q = vim.fn.shellescape
  -- Small headers that make output appear right away (see ~/.config/nvim/runner)
  local runner = vim.fn.stdpath("config") .. "/runner/"
  local build = {
    cpp = "g++ -std=c++20 -O2 -Wall -include " .. q(runner .. "flush.hpp") .. " " .. q(file) .. " -o " .. q(name),
    c = "gcc -std=c17 -O2 -Wall -include " .. q(runner .. "flush.h") .. " " .. q(file) .. " -o " .. q(name),
    java = "javac " .. q(file),
  }
  local run = {
    cpp = "./" .. q(name),
    c = "./" .. q(name),
    java = "java " .. q(name),
    python = "python3 -u " .. q(file), -- -u: print output right away
  }
  local ft = vim.bo.filetype
  if not run[ft] then
    return nil
  end
  local lines = {}
  if build[ft] then
    table.insert(lines, build[ft] .. [[ || { echo; echo '--- compile errors above: fix them and press F6 again. Any key closes ---'; read -rsn1; exit; }]])
  end
  table.insert(lines, [[echo '--- running: type the input (Ctrl+D = end of input) ---']])
  table.insert(lines, run[ft])
  table.insert(lines, [[code=$?; echo]])
  table.insert(lines, [[if [ $code -eq 0 ]; then echo '--- finished: press any key to close ---'; ]]
    .. [[else echo "--- stopped with exit code $code (139 = crash, e.g. out of bounds; 136 = division by zero). Any key closes ---"; fi]])
  table.insert(lines, "read -rsn1")
  return table.concat(lines, "\n")
end

map({ "n", "i", "v" }, "<F6>", function()
  require("stay_insert").pause() -- back to typing after the program finishes
  vim.cmd("stopinsert")
  vim.cmd("silent! write")
  local cmd = run_command()
  if not cmd then
    vim.notify("F6 can run C, C++, Java and Python files", vim.log.levels.WARN)
    return
  end
  -- Run it with bash: the "press any key" part (read -rsn1) is bash syntax,
  -- and Neovim's own shell may be zsh, which doesn't understand it
  -- Open it a moment later: stopinsert only takes effect after this function
  -- ends, and it would otherwise stop the terminal from taking your input
  local cwd = vim.fn.expand("%:p:h")
  vim.schedule(function()
    Snacks.terminal.open({ "bash", "-c", cmd }, { cwd = cwd, auto_close = true, start_insert = true, auto_insert = true })
  end)
end, { desc = "Save, compile and run" })

-- F7: save and submit with the CPH Submit browser extension (see lua/cp/server.lua)
map({ "n", "i", "v" }, "<F7>", function()
  require("cp.server").submit()
end, { desc = "Submit (CPH Submit)" })

-- Find with Ctrl + F
map("n", "<C-f>", "/", { desc = "Find" })

-- Delete the previous word with Ctrl + Backspace
map("i", "<C-BS>", "<C-w>", { desc = "Delete word" })
map("i", "<C-H>", "<C-w>", { desc = "Delete word" }) -- some terminals send this for Ctrl+Backspace

-- Tab / Shift + Tab like VS Code: indent / unindent, keeping the selection.
-- (While typing, Tab still inserts indentation as usual.)
map("n", "<Tab>", ">>", { desc = "Indent line" })
map("n", "<S-Tab>", "<<", { desc = "Unindent line" })
map("i", "<S-Tab>", "<C-d>", { desc = "Unindent line" })
map("x", "<Tab>", ">gv", { desc = "Indent" })
map("x", "<S-Tab>", "<gv", { desc = "Unindent" })
-- Selections made with Shift + arrows are "Select mode": indent, then select again
map("s", "<Tab>", "<C-o>>gv<C-g>", { desc = "Indent" })
map("s", "<S-Tab>", "<C-o><gv<C-g>", { desc = "Unindent" })

-- Ctrl + ] : end of the line. Ctrl + [ : beginning of the line (the first
-- character that isn't a space). kitty sends Ctrl + [ differently from Esc
-- (see kitty.conf), so Esc still works as usual.
local function line_keys(lhs_end, lhs_start)
  map({ "n", "o" }, lhs_end, "$", { desc = "End of line" })
  map("x", lhs_end, "g_", { desc = "End of line" })
  map("i", lhs_end, "<End>", { desc = "End of line" })
  map({ "n", "x", "o" }, lhs_start, "^", { desc = "Beginning of line" })
  map("i", lhs_start, "<Cmd>normal! ^<CR>", { desc = "Beginning of line" })
end
line_keys("<C-]>", "<C-[>")
line_keys("<C-د>", "<C-ج>") -- the same keys with the Arabic layout

-- Arabic layout: Ctrl + an Arabic letter works like Ctrl + the English letter
-- on that key, so the shortcuts above also work while typing Arabic
require("arabic_keys").map_ctrl_keys()
