# Keymaps and Commands
In the [first section](./01-getting-started.md) we:
1. Installed Neovim
2. Understood the basics of organizing Lua scripts
3. Installed a plugin manager "Packer," and installed the first plugin `nvim-tree`

In this section I want to dig a little deeper into:
1. Define custom commands
2. Define custom key mappings

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
