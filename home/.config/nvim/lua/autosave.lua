-- Auto save: your files are saved by themselves, so when you close a problem
-- and open it again later, your code is there.
--   - 1 second after you stop typing
--   - when you leave the file, switch to another app, or quit Neovim
-- Only real files with changes are saved (not new unnamed files).

local M = {}

local timer = nil

local function save(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local bo = vim.bo[buf]
  if bo.buftype ~= "" or not bo.modified or not bo.modifiable or bo.readonly
      or vim.api.nvim_buf_get_name(buf) == "" then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent! lockmarks update") -- write only if changed, keep marks
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("autosave", { clear = true })

  -- 1 second after the last change
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args)
      if timer then
        timer:stop()
      else
        timer = vim.uv.new_timer()
      end
      timer:start(1000, 0, vim.schedule_wrap(function()
        save(args.buf)
      end))
    end,
  })

  -- right away when leaving the file, the window or Neovim
  vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "VimLeavePre", "InsertLeave" }, {
    group = group,
    callback = function(args)
      save(args.buf)
    end,
  })
end

return M
