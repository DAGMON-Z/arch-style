-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Show the real number on the cursor line and distances on all other lines
vim.opt.number = true
vim.opt.relativenumber = true

-- Don't reformat code when saving, so it stays exactly as you wrote it.
-- Format on purpose with Space c f. Space u f toggles format-on-save.
vim.g.autoformat = false

-- Select text with Shift + arrows like VS Code: you stay in typing mode, typing
-- replaces the selection, and a plain arrow key cancels it.
vim.opt.keymodel = "startsel,stopsel"
vim.opt.selectmode = "key,mouse"
-- The selection stops *before* the cursor, like VS Code, where the cursor sits
-- between characters. Without this, Shift+End also selected the invisible line
-- break, so cutting a line pulled the next line up into it.
vim.opt.selection = "exclusive"

-- Indent with 4 spaces, like VS Code (LazyVim's default is 2)
vim.opt.shiftwidth = 4 -- size of one indent level (Tab, >>, automatic indent)
vim.opt.tabstop = 4 -- how wide a real tab character looks
vim.opt.softtabstop = 4 -- Tab and Backspace move by 4 spaces while typing
