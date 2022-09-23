# More plugins
Let's add plugins that I used in vanilla Vim and add more flares to my Neovim

First, `nvim-tree` among other plugins make extensive use of icons that are not readily available in MacOS. This can be patched by downloading a font from [NerdFonts](https://www.nerdfonts.com/), installing it, and configuring the terminal to use that font. I chose `JetBrainsMonoNL NF`.

## (Fancy) file tree
I will add the icons to the file tree:

```lua
use {
  'kyazdani42/nvim-tree.lua',
  requires = {
    'kyazdani42/nvim-web-devicons', -- optional, for file icons
  },
  tag = 'nightly' -- optional, updated every week. (see issue #1193)
}
```

## Status line
A status line is used to display
1. Vim mode
2. git branch
3. show column/row number

```lua
use {
  'nvim-lualine/lualine.nvim',
  requires = { 'kyazdani42/nvim-web-devicons', opt = true }
}
```

Then add the initialization requirements to `init.lua`

```lua
require('lualine').setup {options = { theme = 'gruvbox' }}
```

## Color scheme
Gruvbox is the greatest color scheme of all times

```lua
use "morhetz/gruvbox"
```

After installing the plugin, we need to activate it using Vim's command `colorscheme gruvbox`. This will be organized into `lua/bruce/colors.lua`. We can also set the background color between `dark` and `light`, which will also be organized there:

```lua
-- lua/bruce/colors.lua
vim.cmd("colorscheme gruvbox")
vim.cmd("set bg=bark")
```
