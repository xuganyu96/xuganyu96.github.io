require("plugins")
require("nvim-tree").setup()
require('lualine').setup {options = { theme = 'gruvbox' }}
require("lsp")
require("bruce.sanity")
require("bruce.commands")
require("bruce.keymaps")
require("bruce.colors")
