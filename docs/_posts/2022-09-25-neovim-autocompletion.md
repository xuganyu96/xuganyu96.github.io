---
layout: post
title:  "Setting up autocomplete on Neovim"
date:   2022-09-25
categories: neovim
---

Add the following plugins to `lua/plugins.lua`:

```lua
use "hrsh7th/cmp-nvim-lsp"
use "hrsh7th/cmp-buffer"
use 'hrsh7th/cmp-path'
use 'hrsh7th/cmp-cmdline'
use 'hrsh7th/nvim-cmp'
use 'hrsh7th/cmp-vsnip'
use 'hrsh7th/vim-vsnip'
```

Launch neovim and run `:PackerSync` to install the new plugins

Autocompletion's configuration and startup will be stored in a separate lua file at `lua/autocomplete.lua`

```lua
-- init.lua
require("autocomplete")
```

The content below is adapted from the README of the [source repository of `nvim-cmp`](https://github.com/hrsh7th/nvim-cmp).

```lua
-- lua/autocomplete-.lua
-- Set up nvim-cmp.
local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- Set configuration for specific filetype.
--   cmp.setup.filetype('gitcommit', {
--     sources = cmp.config.sources({
--       { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
--     }, {
--       { name = 'buffer' },
--     })
--   })

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

--   -- Set up lspconfig.
--   local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
--   -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
--   require('lspconfig')['<YOUR_LSP_SERVER>'].setup {
--     capabilities = capabilities
--   }
```

A few things to note:
1. The two lines in the `window` argument of the first setup call are uncommented so the auto-complete dropdown can work as intended
2. The section for "Set up lspconfig" is commented out because it seems to mess with the `"K"` command for documentation preview, declared in `lua/lsp.lua`
3. `cmp.mapping.presets` also include the following keymaps:
    * `<C-n>` and `<C-n>` for next/prev item
    * `<C-y>` for confirming
    * `<C-e>` for aborting
4. As for `cmp.mapping.preset.cmdline` the mapping is as follows:
    * `<C-n>/<Tab>` for next item
    * `<C-p>/<STab>` for prev item
    * `<C-e>` for closing
