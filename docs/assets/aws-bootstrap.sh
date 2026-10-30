#!/bin/bash

set -euo pipefail

BOOTSTRAP_START=$(date +%s%N)
BOOTSTRAP_LOG_PATH="${HOME}/.bootstrap.log"

if [ -f ${BOOTSTRAP_LOG_PATH} ]; then
    cat ${BOOTSTRAP_LOG_PATH}
    exit 1
fi

# [System Packages + Docker]
sudo dnf update -y \
    && sudo dnf install -y git docker gcc clang cmake nodejs npm lldb \
    && sudo dnf groupinstall -y "Development Tools" \
    && sudo dnf install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite \
        sqlite-devel tk-devel libffi-devel xz-devel openssl-devel ninja-build \
        valgrind-devel zstd-devel \
    && sudo systemctl enable docker \
    && sudo systemctl start docker \
    && sudo usermod -aG docker "$USER" \
    && sudo docker run hello-world

# [zsh + Oh-My-Zsh]
sudo dnf install -y zsh util-linux-user \
    && sudo chsh -s $(which zsh) $USER \
    && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# [tmux]
sudo dnf install -y tmux \
    && wget -O ~/.tmux.conf \
        https://raw.githubusercontent.com/xuganyu96/xuganyu96.github.io/refs/heads/main/tmux.conf

# [gitignore]
wget -O ~/.gitignore \
    https://raw.githubusercontent.com/xuganyu96/xuganyu96.github.io/refs/heads/main/global.gitignore \
    && git config --global core.excludesFile "~/.gitignore"

# [Neovim 11.7]
curl -fLO https://github.com/neovim/neovim/releases/download/v0.11.7/nvim-linux-x86_64.tar.gz \
    && sudo rm -rf /opt/nvim-linux-x86_64 \
    && sudo tar -C /opt -xzvf nvim-linux-x86_64.tar.gz \
    && echo 'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"' >> ~/.zshrc \
    && mkdir -p ~/.config/nvim \
    && wget -O ~/.config/nvim/init.lua \
        https://raw.githubusercontent.com/xuganyu96/xuganyu96.github.io/refs/heads/main/neovim/init.lua

# [pyenv + Python]
git clone https://github.com/pyenv/pyenv.git ~/.pyenv \
    && cd ~/.pyenv && src/configure && make -C src \
    && echo '# [pyenv]' >> ~/.zshrc \
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc \
    && echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc \
    && echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc

# [Rust]
curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && source ~/.cargo/env \
    && cargo install ripgrep

BOOTSTRAP_END=$(date +%s%N)
BOOTSTRAP_ELAPSED=$((BOOTSTRAP_END - BOOTSTRAP_START))
echo "Elapsed: $((BOOTSTRAP_ELAPSED / 1000000000)) s"
echo "Bootstrapping last finished: $(date)" >> ${BOOTSTRAP_LOG_PATH}
