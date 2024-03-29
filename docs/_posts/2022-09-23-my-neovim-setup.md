---
layout: post
title:  "Switching to Neovim"
date:   2022-09-23 22:33:45 -0700
categories: neovim
---

# TL;DR
```bash
brew install neovim  # install brew

git clone https://github.com/xuganyu96/xuganyu96.github.io.git
ln $(pwd)/xuganyu96.github.io/neovim ~/.config/nvim  # link personal config

git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim  # download Packer

sudo npm install -g pyright  # install Python language server
```

Launch `nvim`, call `:PackerSync` to install plugins, then restart nvim.

If the icons are not showing up, go to Nerd Fonts to get patched fonts

# Introduction
Through college and my first job I have used a number of text editor and/or IDE's: from Sublime to IntelliJ, to PyCharm, and VSCode. In late 2020 after watching a number of Youtube videos evangelizing Vim, I decided to give it a go and loved being able to do everything while keeping my hands on the home row at all times.

However, Vim is not perfect. For one, my instance of Vim, installed through `brew` on a 2019 16-inch MacBook pro (my work laptop), could not render underscore or undercurl correctly. In addition, language support in Vim, for which I chose CoC + PyRight, takes jumping through a lot of hoops to set up correctly, and even then the linting and diagnostics don't work exactly the way I want.

After watching [this video](https://www.youtube.com/watch?v=p0Q3oDY9A5s), I am convinced to switch again from vanilla Vim to Neovim. While Neovim is a fork of Vim that keeps the majority of the source code, the setup process is significantly different, especially given that I want to use Lua instead of Vimscript as the scripting language. This post documents the process by which I learned the basics of Neovim configuration using Lua, as well as my choices of plugins and default settings.

# Installing Neovim
Neovim can be easily installed through `brew` on MacOS:

```bash
brew install neovim
nvim --version  # I got v0.7.2, which has a native lsp client
```

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

```bash
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

## Commands
Vim itself already supports custom commands. For example, to shorthand the `:NvimTreeToggle` command, you can define:

```vimscript
command TT NvimTreeToggle
```

To invoke the declaration of custom command in Lua, you can use the global `vim` object to invoke the `vim.cmd` function.

For now, I will organize all custom commands into a single `lua/custom-commands.lua` module, in which I will add the first batch of commands:

```lua
vim.cmd("command TT NvimTreeToggle")
vim.cmd("command TF NvimTreeFocus")
```

Of course, to load the `custom-commands.lua`, I will add the following line to `init.lua`:

```lua
require("custom-commands")
```

## Custom key maps
If the shorthand commands still aren't fast enough, I can try declaring custom key maps (keys or key combinations).

There are a variety of commands in Vim that can be used to map key combinations. For simplicity, I will only use `nnoremap` at this moment. According to `:help nnoremap`, this command is understood as follows:
1. The first `n` stands for "Normal mode"; there are other commands like `vnoremap` for visual mode, `xnoremap` for Ex mode, etc.
2. `noremap` means that the target of the map cannot be used to map to a second target. This prevents recursive key maps.

For this time, I will organize all key maps into a single `custom-keymaps.lua` and add it to `init.lua`:

```lua
vim.g.mapleader = " "  -- the <leader> key referenced below
vim.keymap.set("n", "<Leader>t", ":NvimTreeToggle<CR>")
vim.keymap.set("n", "<Leader>f", ":NvimTreeFocus<CR>")
```

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

# Language support
For langauge support I want to be able to

1. Given a keyword, go to the place where it is defined
2. Given a keyword, find places where it is referenced
3. Autocompletion
4. Preview the signature of a method

Documentation can be found with `:help lsp`

Per `:help lsp-quickstart`:

1. Install `neovim/nvim-lspconfig` plugin
2. Install some language server. Per [documentation of the plugin above](https://github.com/neovim/nvim-lspconfig), I will go with pyright (written with Node.js): `sudo npm install -g pyright`

There is a recommended configuration on `neovim/nvim-lspconfig`, which I will place into `lua/lsp.lua` and source in `init.lua`:

```lua
require("lsp")
```
