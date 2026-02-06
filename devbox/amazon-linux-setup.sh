#!/usr/bin/env bash
set -euo pipefail

if [[ -t 1 ]]; then
    RESET="\033[0m"
    BLUE="\033[1;34m"
    GREEN="\033[1;32m"
    YELLOW="\033[1;33m"   # orange-ish / warning
    RED="\033[1;31m"      # error
else
    RESET=""
    BLUE=""
    GREEN=""
    YELLOW=""
    RED=""
fi

printinfo() {
    printf "%b\n" "${BLUE}ℹ $1${RESET}"
}

printsuccess() {
    printf "%b\n" "${GREEN}✔ $1${RESET}"
}

printwarning() {
    printf "%b\n" "${YELLOW}⚠ $1${RESET}"
}

printerror() {
    printf "%b\n" "${RED}✖ $1${RESET}" >&2
}

# Minimal setup to get Docker to work
sudo dnf update -y \
    && sudo dnf install -y \
        git \
        docker \
        gcc \
        clang \
        cmake \
        nodejs npm \
    && sudo systemctl enable docker \
    && sudo systemctl start docker \
    && sudo usermod -aG docker "$USER" \
    && sudo docker run hello-world
printsuccess "Docker installed successfully."
printinfo "Log out for docker group changes to take effect."

# Add SSH keys
# TODO: figure out how to use SSH agent forwarding to avoid copying keys
eval "$(ssh-agent -s)" && sleep 1
if [[ -f ~/.ssh/id_ed25519 ]]; then
    ssh-add ~/.ssh/id_ed25519
fi
if [[ -f ~/.ssh/id_rsa ]]; then
    ssh-add ~/.ssh/id_rsa
fi

# Set up bash-it to have nice terminal
printinfo "Installing bash-it" 
preferredtheme="clean" # robbyrussell is nice, too
if [ -d ~/.bash_it ]; then
    printwarning "~/.bash_it already exists; skipping setup"
else
    git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
    ~/.bash_it/install.sh --silent --append-to-config
    cp ~/.bashrc ~/.bashrc.bak
    sed -i "s/bobby/${preferredtheme}/g" ~/.bashrc
fi

# Install latest stable Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
echo 'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"' >> ~/.bashrc

# Install personl config
printinfo "Installing xuganyu96.github.io"
if [ -d ~/.config ]; then
    printwarning "~/.config already exists"
else
    mkdir ~/.config
    printinfo "Created directory ~/.config"
fi
if [ -d ~/xuganyu96.github.io ]; then
    printwarning "~/xuganyu96.github.io already exists; skipping setup"
else
    git clone --depth 1 https://github.com/xuganyu96/xuganyu96.github.io.git
    ln -s ~/xuganyu96.github.io/neovim ~/.config/nvim
    ln -s ~/xuganyu96.github.io/tmux.conf ~/.tmux.conf
    ln -s ~/xuganyu96.github.io/global.gitignore ~/.gitignore
    git config --global core.excludesFile "~/.gitignore"
    git config --global user.name "Ganyu (Bruce) Xu"
    git config --global user.email "xuganyu@berkeley.edu"
    printsuccess "Installed xuganyu96.github.io"
    printinfo "Neovim config:       $HOME/.config/nvim"
    printinfo "Tmux config:         $HOME/.tmux.conf"
    printinfo "Global Git ignore:   $HOME/.gitignore"

    # build code-server container
    sudo docker build \
        -t devbox:latest \
        -f xuganyu96.github.io/devbox/code-server/Dockerfile \
        xuganyu96.github.io/devbox/code-server
fi

