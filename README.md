# xuganyu96.github.io
My personal website: xuganyu96.github.io

## Managing dot files
From the project root, run the following commands:

```bash
# Copy over neovim config
ln -s $(pwd)/neovim ~/.config/nvim

# Copy over tmux config
ln -s $(pwd)/tmux.conf ~/.tmux.conf

# Copy over global gitignore
ln -s $(pwd)/global.gitignore ~/.gitignore
git config --global core.excludesFile "~/.gitignore"
```

# What's next
- [ ] Read `crypto-bigint` source code and try to contribute
    - Small issues: https://github.com/RustCrypto/crypto-bigint/issues/268 (renaming things with `_vartime` suffix
- [ ] What about signing PyPI packages?