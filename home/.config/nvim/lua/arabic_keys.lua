-- Neovim with the Arabic keyboard layout.
--
-- Neovim's commands are English letters (q, :q, dd, Space f f ...). With the
-- Arabic layout on, those keys type Arabic letters instead, so nothing worked.
--
-- 1. Outside insert mode the keyboard switches to English by itself, and when
--    you start typing again it switches back to Arabic (if you were typing
--    Arabic). Uses hyprctl, so it only works on Hyprland.
-- 2. While typing Arabic, Ctrl shortcuts (Ctrl+S, Ctrl+Z, Ctrl+A, Ctrl+C ...)
--    arrive as Ctrl + an Arabic letter. Each one is mapped to the same
--    shortcut with the English letter on that key.

local M = {}

-- Arabic letter -> English key in the same place (the standard Arabic layout)
M.keys = {
  ["ض"] = "q", ["ص"] = "w", ["ث"] = "e", ["ق"] = "r", ["ف"] = "t",
  ["غ"] = "y", ["ع"] = "u", ["ه"] = "i", ["خ"] = "o", ["ح"] = "p",
  ["ج"] = "[", ["د"] = "]",
  ["ش"] = "a", ["س"] = "s", ["ي"] = "d", ["ب"] = "f", ["ل"] = "g",
  ["ا"] = "h", ["ت"] = "j", ["ن"] = "k", ["م"] = "l", ["ك"] = ";", ["ط"] = "'",
  ["ئ"] = "z", ["ء"] = "x", ["ؤ"] = "c", ["ر"] = "v", ["ﻻ"] = "b",
  ["ى"] = "n", ["ة"] = "m", ["و"] = ",", ["ز"] = ".", ["ظ"] = "/",
  ["ذ"] = "`",
}

-- 2. Ctrl + Arabic letter does what Ctrl + the English letter does
function M.map_ctrl_keys()
  for arabic, english in pairs(M.keys) do
    vim.keymap.set({ "n", "i", "v", "o", "c", "t" }, "<C-" .. arabic .. ">", "<C-" .. english .. ">", {
      remap = true, -- run your mapping for the English key, or Neovim's own command
      silent = true,
      desc = "Ctrl+" .. english .. " (Arabic layout)",
    })
  end
end

-- 1. Switch the layout automatically
local saved = nil -- the layout to bring back when you start typing again

local function on_hyprland()
  return vim.env.HYPRLAND_INSTANCE_SIGNATURE ~= nil and vim.fn.executable("hyprctl") == 1
end

-- The layout number of the main keyboard: 0 is English, 1 is Arabic
local function current_layout(callback)
  vim.system({ "hyprctl", "devices", "-j" }, { text = true }, function(result)
    local ok, data = pcall(vim.json.decode, result.stdout or "")
    if not ok or type(data) ~= "table" then
      return
    end
    for _, keyboard in ipairs(data.keyboards or {}) do
      if keyboard.main then
        callback(keyboard.active_layout_index)
        return
      end
    end
  end)
end

local function set_layout(index)
  vim.system({ "hyprctl", "switchxkblayout", "all", tostring(index) })
end

local function to_english()
  current_layout(function(index)
    if index and index ~= 0 then
      saved = index
      set_layout(0)
    end
  end)
end

local function restore()
  if saved then
    set_layout(saved)
    saved = nil
  end
end

function M.setup_auto_switch()
  if not on_hyprland() then
    return
  end
  local group = vim.api.nvim_create_augroup("arabic_keys", { clear = true })
  local function au(events, fn)
    vim.api.nvim_create_autocmd(events, { group = group, callback = fn })
  end
  -- leaving insert mode, or coming back to Neovim: English for commands
  au("InsertLeave", to_english)
  au("FocusGained", function()
    if not vim.fn.mode():match("^[iR]") then
      to_english()
    end
  end)
  -- typing again: back to the layout you were typing in
  au("InsertEnter", restore)
  -- going to another app or quitting: give your layout back
  au({ "FocusLost", "VimLeavePre" }, restore)
  -- Neovim just opened (autocmds load after startup, so do it now)
  if not vim.fn.mode():match("^[iR]") then
    to_english()
  end
end

return M
