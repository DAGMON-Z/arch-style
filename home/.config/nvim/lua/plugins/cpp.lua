-- C++ for competitive programming: use the clangd installed by pacman
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          mason = false, -- do not download a second copy of clangd
          cmd = {
            "clangd",
            "--background-index",
            "--completion-style=detailed",
            "--header-insertion=never", -- do not add #include lines by itself
            "--function-arg-placeholders=false",
            "--fallback-style=llvm",
          },
        },
      },
    },
  },
}
