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

## Plugin manager
Follow the instruction on [Packer's website](https://github.com/wbthomason/packer.nvim):

```
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

