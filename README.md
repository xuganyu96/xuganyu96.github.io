# xuganyu96.github.io
My personal website

## Managing dot files

```bash
# From project root
ln -s $(pwd)/tmux.conf ~/.tmux.conf
ln -s $(pwd)/global.gitignore ~/.gitignore
git config --global core.excludesFile "~/.gitignore"
```
