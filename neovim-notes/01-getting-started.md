# Switching to Neovim
Following [this video](https://youtu.be/p0Q3oDY9A5s), I am convinced to give Neovim a try. Here are my goals:

1. Go to definition
2. Autocompletion
3. Highlight bad whitespaces
4. Underlining errors and warnings, and being able to turn them off
5. Search for references
6. File tree
7. Fuzzy file finder
8. Configurations need to be portable
9. Rulers for line width

Some sample code is put in the [./src](./src) directory to test the functionalities.

Neovim can be installed using brew `brew install neovim` and started using the command `nvim`.

## Config location
With MacOS, Neovim first looks in `~/.config/nvim` directory for configuration files. The first script that loads can be either `init.lua` or `init.vim`, although I am switching from Vim to Neovim for the Lua support, so `init.vim` it is.

With Lua, we can separate configurations that serve different purposes into different files. The Lua scripts will be placed in `~/.config/nvim/lua` and accessed by the initialization script using the `require` keyword:

```lua
print("Hello, world!")
require("plugins") -- runs ~/.config/nvim/lua/plugins.lua
```

`~/.config/nvim/lua/plugins.lua` is where we will specify the plugins.

## Plugin manager
Follow the instruction on [Packer's website](https://github.com/wbthomason/packer.nvim):

```
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

At this point Packer is not recognized by Neovim yet (Packer commands don't work). We can fix that by adding the following lines to `~/.config/nvim/lua/plugins.lua`

```lua
-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
end)
```

Now when we restart Neovim, the packer commands should be recognized, although since we have not specified any plugins, the commands won't do anything

One can wipe the entire Packer installation clean by deleting Neovim's data directory at `~/.local/share/nvim`

## First plugin: file tree
Let's try our first plugin: a [file tree](https://github.com/kyazdani42/nvim-tree.lua)!

First add the following lines to `plugins.lua`:

```lua
use 'kyazdani42/nvim-tree.lua'  -- skipping the fancy stuff
```

After that, restart Neovim and run the `:PackerSync` command. A panel should pop up indicating that the installation is completed.

Add the following line to `init.lua`

```lua
require("nvim-tree").setup()
```

Now when Noevim starts, it will automatically load and initialize the file tree plugin. At this point, the commands should work, like `:NvimTreeToggle`.

To uninstall the plugin, first remove the `use` statement from `plugins.lua`. Restart Neovim and run `:PackerClean` to uninstall the file tree plugin.
