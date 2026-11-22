-- Stay in insert mode (typing) unless you press Esc yourself.
--
-- Some things leave insert mode on their own: F5 and F6 open a window, Ctrl+S
-- used to press Esc after saving, copying a selection ends in normal mode.
-- This brings you back to typing afterwards, with the cursor where it was.
-- Only a real Esc key press keeps you in normal mode.

local M = {}

local typing = false -- you were typing, and haven't pressed Esc since
local paused = false -- a window (F5 results, F6 terminal) is about to open
local last_key = "" -- the last key you actually pressed
local saved = nil -- where the cursor was when insert mode ended

local function is_file(buf)
  return vim.bo[buf].buftype == "" and vim.bo[buf].modifiable
end

-- Go back to insert mode, with the cursor where it was when typing stopped
local function resume(use_saved)
  local buf = vim.api.nvim_get_current_buf()
  if not typing or paused or vim.fn.mode() ~= "n" or not is_file(buf) then
    return
  end
  if use_saved and saved and saved.buf == buf then
    local row, col = saved.row, saved.col
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
    if line then
      if col >= #line then
        vim.api.nvim_win_set_cursor(0, { row, math.max(#line - 1, 0) })
        vim.cmd("startinsert!") -- at the end of the line
        return
      end
      vim.api.nvim_win_set_cursor(0, { row, col })
    end
  end
  vim.cmd("startinsert")
end

--- Call before opening a window that should be closed first (F5, F6)
function M.pause()
  paused = true
  -- in case no window opens after all, carry on after a few seconds
  vim.defer_fn(function()
    if paused and is_file(vim.api.nvim_get_current_buf()) then
      paused = false
      resume(true)
    end
  end, 5000)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("stay_insert", { clear = true })

  -- Remember the last key you pressed, to tell a real Esc from anything else
  vim.on_key(function(_, typed)
    if typed and typed ~= "" then
      last_key = vim.fn.keytrans(typed)
    end
  end, vim.api.nvim_create_namespace("stay_insert"))

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      typing = true
    end,
  })

  -- Where the cursor was, before insert mode moves it back one character
  vim.api.nvim_create_autocmd("InsertLeavePre", {
    group = group,
    callback = function(args)
      local pos = vim.api.nvim_win_get_cursor(0)
      saved = { buf = args.buf, row = pos[1], col = pos[2] }
    end,
  })

  -- Ended up in normal mode: by your Esc (stay), or by something else (resume)
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "*:n",
    callback = function()
      if last_key == "<Esc>" then
        typing = false
        return
      end
      -- After a selection, keep the cursor where it is. Otherwise (typing,
      -- terminal) put it back where you were typing.
      local from_selection = vim.v.event.old_mode:match("^[vVsS\22\19]") ~= nil
      -- wait a moment: a shortcut may pass through normal mode on its way
      -- somewhere else (Ctrl+A goes on to select everything)
      vim.defer_fn(function()
        resume(not from_selection)
      end, 30)
    end,
  })

  -- Back in your code after a window closed (F5 results, F6 terminal, Ctrl+`)
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    group = group,
    callback = function(args)
      if is_file(args.buf) then
        paused = false
        vim.schedule(function()
          resume(true)
        end)
      end
    end,
  })
end

return M
