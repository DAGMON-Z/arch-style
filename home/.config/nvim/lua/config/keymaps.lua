-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- VS Code style shortcuts, so Neovim feels familiar.
-- The normal Neovim keys still work too (u = undo, Ctrl+R = redo, y = copy...).
-- Modes: "n" normal, "i" typing (insert), "v" selection (visual).
local map = vim.keymap.set

-- Undo / redo. Ctrl+Z would otherwise pause Neovim and drop you to the shell.
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
  vim.cmd("stopinsert")
  vim.cmd("silent! write")
  vim.cmd("CompetiTest run")
end, { desc = "Save and run sample tests" })

-- Find with Ctrl + F
map("n", "<C-f>", "/", { desc = "Find" })

-- Delete the previous word with Ctrl + Backspace
map("i", "<C-BS>", "<C-w>", { desc = "Delete word" })
map("i", "<C-H>", "<C-w>", { desc = "Delete word" }) -- some terminals send this for Ctrl+Backspace

-- Indent / unindent a selection with Tab / Shift + Tab
map("v", "<Tab>", ">gv", { desc = "Indent" })
map("v", "<S-Tab>", "<gv", { desc = "Unindent" })
