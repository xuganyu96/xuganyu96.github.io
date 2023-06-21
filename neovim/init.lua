require("plugins")
require("nvim-tree").setup()
require('lualine').setup {options = { theme = 'gruvbox' }}
require("lsp")
require("autocomplete")
require("bruce.commands")
require("bruce.keymaps")
require("bruce.colors")
require("bruce.sanity")
