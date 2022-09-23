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
