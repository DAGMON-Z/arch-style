-- Competitive programming: receive problems from the Competitive Companion
-- browser extension, and test your code against the sample tests.
--
-- Problems arrive automatically: while Neovim is open, it listens for the
-- extension. Click the extension's green "+" button in the browser and the
-- problem opens in Neovim, with its sample tests saved. No keys needed.
--
-- Keys: F5 runs the tests (see keymaps.lua), Space C t too. See docs/09-neovim.md.

-- Start listening for problems and contests from the browser
local function listen(show_errors)
  local cfg = require("competitest.config").current_setup
  local err = require("competitest.receive").start_receiving(
    "persistently", cfg.companion_port, show_errors, cfg.receive_print_message, nil, cfg
  )
  -- An error at startup usually means another Neovim is already listening.
  -- That one receives the problems, so stay quiet.
  if err and show_errors then
    vim.notify("CompetiTest: " .. err, vim.log.levels.WARN)
  end
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
      { "<leader>Cs", "<cmd>CompetiTest receive status<cr>", desc = "Is it listening?" },
      -- Only needed if another Neovim was listening and you closed it
      {
        "<leader>Cr",
        function()
          require("competitest.receive").stop_receiving()
          listen(true)
        end,
        desc = "Listen for problems here",
      },
    },
    opts = {
      -- Same flags as the judge build in the docs
      compile_command = {
        cpp = { exec = "g++", args = { "-std=c++20", "-O2", "-Wall", "$(FNAME)", "-o", "$(FNOEXT)" } },
      },
      -- Port 27121 is where Competitive Companion sends problems
      companion_port = 27121,
      -- New problems start from this template
      template_file = { cpp = vim.fn.stdpath("config") .. "/templates/cp.cpp" },
      -- Save problems as ~/cp/<site>/<contest>/<problem>.cpp
      received_files_extension = "cpp",
      received_problems_path = "$(HOME)/cp/$(JUDGE)/$(CONTEST)/$(PROBLEM).$(FEXT)",
      received_contests_directory = "$(HOME)/cp/$(JUDGE)/$(CONTEST)",
      -- Don't ask where to save: use the paths above
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
