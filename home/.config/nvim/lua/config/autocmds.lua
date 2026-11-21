-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Arabic layout: switch to English outside insert mode, so Neovim's commands
-- work, and back to Arabic when you type again (see lua/arabic_keys.lua)
require("arabic_keys").setup_auto_switch()

-- Open files in insert mode, so you can type right away (normal mode only
-- when you press Esc). Only for real files: the start screen, file finder,
-- test results and terminal work as before.
local function start_typing(buf)
  vim.schedule(function()
    if vim.api.nvim_get_current_buf() == buf and vim.bo[buf].buftype == ""
        and vim.bo[buf].modifiable and vim.fn.mode() == "n" then
      vim.cmd("startinsert")
    end
  end)
end
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("open_in_insert", { clear = true }),
  callback = function(args)
    start_typing(args.buf)
  end,
})
-- The file given on the command line (nvim file.cpp) was opened before this
-- file loaded, so do it for that one now
if vim.api.nvim_buf_get_name(0) ~= "" then
  start_typing(vim.api.nvim_get_current_buf())
end
