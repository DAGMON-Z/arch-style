-- Autocomplete is turned off on purpose, to practise writing code from memory.
-- Suggestions no longer pop up while typing. Press Ctrl+Space to show them
-- when you really need them. Error checking (clangd) stays on.
-- To turn autocomplete back on, delete this file.
return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = { auto_show = false },          -- no list popping up while typing
        ghost_text = { enabled = false },      -- no grey suggested text
        documentation = { auto_show = false }, -- no automatic help popups
      },
    },
  },
}
