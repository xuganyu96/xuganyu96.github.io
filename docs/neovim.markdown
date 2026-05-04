---
title: Neovim
layout: page
---

# Install Neovim on Apple Silicon from pre-built archive

```bash
curl -LO https://github.com/neovim/neovim/releases/download/v0.11.7/nvim-macos-arm64.tar.gz
rm -rf /opt/nvim-macos-arm64
sudo tar -C /opt -xzvf nvim-macos-arm64.tar.gz
export PATH="$PATH:/opt/nvim-macos-arm64/bin"
```

I chose to install Neovim from pre-built archive instead of Homebrew because I want to stick with v0.11 with my current `init.lua`.
