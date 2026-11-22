-- Competitive programming: receive problems from the Competitive Companion
-- browser extension, and test your code against the sample tests.
--
-- Problems arrive automatically: while Neovim is open, it listens for the
-- extension. Click the extension's green "+" button in the browser and the
-- problem opens in Neovim, with its sample tests saved. No keys needed.
-- It's saved in the folder you opened Neovim in (see save_folder below).
--
-- Keys: F5 runs the tests (see keymaps.lua), Space C t too. See docs/09-neovim.md.

-- Where received problems go: the folder Neovim was opened in (run `nvim`
-- inside the folder you want). If that folder isn't meant for problems, Neovim
-- asks where to save, and suggests ~/cp/<site>/<contest>/.

-- Replace characters that can't be in file names
local function clean(name)
  return (name:gsub('[<>:"/\\|?*]', "_"))
end

-- Not for problems: home itself, hidden folders (~/.config, ~/.local, ...),
-- the standard home folders themselves (Downloads, Documents, ...), and
-- anything outside home. Folders inside Documents etc. are fine.
local function problem_folder(dir)
  local home = vim.uv.os_homedir()
  if dir == home or dir:sub(1, #home + 1) ~= home .. "/" then
    return false
  end
  local rest = dir:sub(#home + 2)
  if rest:match("^%.") or rest:match("/%.") then
    return false
  end
  local standard = { "Desktop", "Documents", "Downloads", "Music", "Pictures", "Videos", "Public", "Templates" }
  return not vim.tbl_contains(standard, rest)
end

-- Turn the "where to save?" question on or off for this problem
local function ask_where(ask)
  local cfg = require("competitest.config").current_setup
  cfg.received_problems_prompt_path = ask
  cfg.received_contests_prompt_directory = ask
end

-- The folder to save in: the current one, or the suggestion ~/cp/<site>/<contest>
local function save_folder(task)
  local dir = vim.fn.getcwd()
  if problem_folder(dir) then
    ask_where(false)
    return dir
  end
  ask_where(true)
  local judge, contest = task.group:match("^(.-) %- (.+)$")
  judge, contest = judge or task.group, contest or "unknown_contest"
  return vim.uv.os_homedir() .. "/cp/" .. clean(judge) .. "/" .. clean(contest)
end

-- Start listening for the browser extensions. lua/cp/server.lua listens on
-- port 27121: it receives problems from Competitive Companion (and passes them
-- to competitest on port 27122) and hands F7 submissions to CPH Submit.
local function listen(show_errors)
  local cfg = require("competitest.config").current_setup
  local err = require("cp.server").start()
    or require("competitest.receive").start_receiving(
      "persistently", cfg.companion_port, show_errors, cfg.receive_print_message, nil, cfg
    )
  -- An error at startup usually means another Neovim is already listening.
  -- That one receives the problems and submits, so stay quiet.
  if err and show_errors then
    vim.notify("CP: " .. err, vim.log.levels.WARN)
  end
end

local function stop_listening()
  require("cp.server").stop()
  require("competitest.receive").stop_receiving()
end

return {
  {
    "xeluxee/competitest.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    cmd = "CompetiTest",
    -- load right after Neovim opens, so it can start listening
    event = "VeryLazy",
    keys = {
      { "<leader>C", "", desc = "+competitive programming" },
      { "<leader>Ct", "<cmd>CompetiTest run<cr>", desc = "Run sample tests" },
      { "<leader>Ca", "<cmd>CompetiTest add_testcase<cr>", desc = "Add a test" },
      { "<leader>Ce", "<cmd>CompetiTest edit_testcase<cr>", desc = "Edit a test" },
      { "<leader>Cd", "<cmd>CompetiTest delete_testcase<cr>", desc = "Delete a test" },
      {
        "<leader>Cs",
        function()
          local yes = require("cp.server").is_listening()
          vim.notify(yes and "This Neovim receives problems and submits (port 27121)."
            or "Not listening here. Press Space C r to listen in this Neovim.", vim.log.levels.INFO, { title = "CP" })
        end,
        desc = "Is it listening?",
      },
      -- Only needed if another Neovim was listening and you closed it
      {
        "<leader>Cr",
        function()
          stop_listening()
          listen(true)
          if require("cp.server").is_listening() then
            vim.notify("Listening here now.", vim.log.levels.INFO, { title = "CP" })
          end
        end,
        desc = "Listen for problems here",
      },
    },
    opts = {
      -- Same flags as the judge build in the docs
      -- The compiled program goes in "cph files" too, so the problem folder
      -- only shows your solutions
      compile_command = {
        cpp = {
          exec = "bash",
          args = { "-c", 'mkdir -p "cph files" && g++ -std=c++20 -O2 -Wall "$(FNAME)" -o "cph files/$(FNOEXT)"' },
        },
      },
      run_command = {
        cpp = { exec = "cph files/$(FNOEXT)" },
      },
      -- Competitive Companion sends to port 27121, where lua/cp/server.lua
      -- listens and passes problems on to competitest here
      companion_port = 27122,
      -- New problems start from this template
      template_file = { cpp = vim.fn.stdpath("config") .. "/templates/cp.cpp" },
      -- Save problems in the current folder, or ask (see save_folder above)
      received_files_extension = "cpp",
      received_problems_path = function(task, ext)
        return save_folder(task) .. "/" .. require("cp.server").file_name(task.name) .. "." .. ext
      end,
      received_contests_directory = function(task)
        return save_folder(task)
      end,
      -- Each problem of a contest: its title only (see cp/server.lua)
      received_contests_problems_path = function(task, ext)
        return require("cp.server").file_name(task.name) .. "." .. ext
      end,
      -- Test files (input and output) go in a "cph files" folder next to the
      -- problems, so the problem folder only shows your solutions
      testcases_directory = "cph files",
      -- Ask where to save only when save_folder says so
      received_problems_prompt_path = false,
      received_contests_prompt_directory = false,
      received_contests_prompt_extension = false,
    },
    config = function(_, opts)
      require("competitest").setup(opts)
      -- Not when Neovim runs without a screen (scripts, headless)
      if #vim.api.nvim_list_uis() == 0 then
        return
      end
      -- Listening this way asks "testcases only or the full problem?" for each
      -- problem. Always answer "Problem". Every other question works as usual.
      local confirm = vim.fn.confirm
      vim.fn.confirm = function(msg, ...)
        if type(msg) == "string" and msg:find("^One task received") then
          return 2
        end
        return confirm(msg, ...)
      end
      listen(false)
    end,
  },
}
