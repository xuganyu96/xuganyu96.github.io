#!/bin/bash

setup_pyenv() {
    echo ">>>>>>>> Installing pyenv"
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    cd ~/.pyenv && src/configure && make -C src
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
    source ~/.bashrc
    echo "Installed pyenv <<<<<<<<<<"
    echo ">>>>>>>> Installing Python 3.12.4"
    pyenv install 3.12.4
    pyenv global 3.12.4
    python -m pip install --upgrade pip setuptools wheel
    echo "Installed Python 3.12.4 <<<<<<<<<<"
}

setup_rust() {
    echo ">>>>>>>> Installing Rust"
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source ~/.cargo/env
    echo "Installed Rust <<<<<<<<<<"
}

setup_neovim() {
    echo ">>>>>>>> Installing Neovim"
    git clone --depth 1 --branch v0.9.5 https://github.com/neovim/neovim.git
    cd neovim
    echo "Compiling Neovim ........"
    make CMAKE_BUILD_TYPE=Release > /dev/null
    echo "Installing Neovim ........"
    sudo make install > /dev/null
    cd ~
    echo "Installed Neovim <<<<<<<<<<"
}

setup_docker() {
    echo ">>>>>>>> Setting up Docker"
    sudo yum install -y -q docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo docker run --rm hello-world
    echo "Installed Docker <<<<<<<<<<"
}

install_personal_config() {
    echo ">>>>>>>> Installing xuganyu96.github.io"
    git clone https://github.com/xuganyu96/xuganyu96.github.io.git
    if [ -d ~/.config ]; then
        echo "~/.config already exists"
    else
        mkdir ~/.config
        echo "Created directory ~/.config"
    fi
    ln -s ~/xuganyu96.github.io/neovim ~/.config/nvim
    ln -s ~/xuganyu96.github.io/tmux.conf ~/.tmux.conf
    ln -s ~/xuganyu96.github.io/global.gitignore ~/.gitignore
    git config --global core.excludesFile "~/.gitignore"
    git config --global user.name "Ganyu (Bruce) Xu"
    git config --global user.email "xuganyu@berkeley.edu"
    echo "Installed xuganyu96.github.io <<<<<<<<<<"
}

install_sys_deps() {
    echo ">>>>>>>> Installing system dependencies"
    sudo yum update -y
    sudo yum install -y -q git gcc cmake tmux npm clang
    sudo yum groupinstall "Development Tools" -y -q
    sudo yum install -y -q zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel tk-devel \
        libffi-devel xz-devel openssl-devel npm
    echo "Installed system dependencies <<<<<<<<<<"
}

setup_all() {
    install_sys_deps
    install_personal_config
    setup_docker
    setup_neovim
    setup_pyenv
    setup_rust
}

export -f install_sys_deps
export -f install_personal_config
export -f setup_docker
export -f setup_neovim
export -f setup_pyenv
export -f setup_rust
export -f setup_all

