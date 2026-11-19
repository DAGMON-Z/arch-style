-- Competitive programming: receive problems from the Competitive Companion
-- browser extension, and test your code against the sample tests.
-- Keys: Space C r (receive problem), Space C t (run tests). See docs/09-neovim.md.
return {
  {
    "xeluxee/competitest.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    cmd = "CompetiTest",
    keys = {
      { "<leader>C", "", desc = "+competitive programming" },
      { "<leader>Cr", "<cmd>CompetiTest receive problem<cr>", desc = "Receive problem from browser" },
      { "<leader>Cc", "<cmd>CompetiTest receive contest<cr>", desc = "Receive whole contest" },
      { "<leader>Ct", "<cmd>CompetiTest run<cr>", desc = "Run sample tests" },
      { "<leader>Ca", "<cmd>CompetiTest add_testcase<cr>", desc = "Add a test" },
      { "<leader>Ce", "<cmd>CompetiTest edit_testcase<cr>", desc = "Edit a test" },
      { "<leader>Cd", "<cmd>CompetiTest delete_testcase<cr>", desc = "Delete a test" },
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
    },
  },
}
