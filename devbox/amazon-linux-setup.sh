#!/bin/bash

setup_pyenv() {
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    cd ~/.pyenv && src/configure && make -C src
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
    source ~/.bashrc
    pyenv install 3.12.4 --verbose
    pyenv global 3.12.4
    python -m pip install --upgrade pip setuptools wheel
}

setup_rust() {
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source ~/.cargo/env
}

setup_neovim() {
    git clone --depth 1 --branch v0.9.5 https://github.com/neovim/neovim.git
    cd neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd ~
}

setup_docker() {
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo docker run --rm hello-world
    echo "Finished installing Docker."
}

######## The main setup ########
sudo yum update -y
sudo yum install -y git gcc cmake tmux npm clang
sudo yum groupinstall "Development Tools" -y
sudo yum install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel tk-devel \
	libffi-devel xz-devel openssl-devel npm

# Personal dotfiles
git clone https://github.com/xuganyu96/xuganyu96.github.io.git
cd xuganyu96.github.io
if [ -d ~/.config ]; then
    echo "~/.config already exists"
else
    mkdir ~/.config
    echo "Created directory ~/.config"
fi
ln -s $(pwd)/neovim ~/.config/nvim
ln -s $(pwd)/tmux.conf ~/.tmux.conf
ln -s $(pwd)/global.gitignore ~/.gitignore
git config --global core.excludesFile "~/.gitignore"
git config --global user.name "Ganyu (Bruce) Xu"
git config --global user.email "xuganyu@berkeley.edu"
cd ~

setup_docker
setup_neovim
setup_pyenv
setup_rust
# TODO: maybe code-server is also a good idea

