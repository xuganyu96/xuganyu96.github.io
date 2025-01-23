#!/bin/bash

print_info() {
    echo -e "\033[1;34m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m$1\033[0m"
}

print_warning() {
    echo -e "\033[1m\033[91m$1\033[0m"
}

setup_pyenv() {
    print_info ">>>>>>>> Installing pyenv"
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    cd ~/.pyenv && src/configure && make -C src
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
    source ~/.bashrc
    print_success "Installed pyenv <<<<<<<<<<"
    print_info ">>>>>>>> Installing Python 3.12.4"
    pyenv install 3.12.4
    pyenv global 3.12.4
    python -m pip install --upgrade pip setuptools wheel
    cd ~
    print_success "Installed Python 3.12.4 <<<<<<<<<<"
}

setup_rust() {
    print_info ">>>>>>>> Installing Rust"
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source ~/.cargo/env
    print_success "Installed Rust <<<<<<<<<<"
}

setup_neovim() {
    print_info ">>>>>>>> Installing Neovim"
    git clone --depth 1 --branch stable https://github.com/neovim/neovim.git
    cd neovim
    print_info "Compiling Neovim ........"
    make CMAKE_BUILD_TYPE=Release
    print_info "Installing Neovim ........"
    sudo make install
    cd ~
    print_success "Installed Neovim <<<<<<<<<<"
}

setup_docker() {
    print_info ">>>>>>>> Setting up Docker"
    sudo yum install -y -q docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo docker run --rm hello-world
    print_success "Installed Docker <<<<<<<<<<"
}

install_personal_config() {
    print_info ">>>>>>>> Installing xuganyu96.github.io"
    git clone https://github.com/xuganyu96/xuganyu96.github.io.git
    if [ -d ~/.config ]; then
        print_warning "~/.config already exists"
    else
        mkdir ~/.config
        print_success "Created directory ~/.config"
    fi
    ln -s ~/xuganyu96.github.io/neovim ~/.config/nvim
    ln -s ~/xuganyu96.github.io/tmux.conf ~/.tmux.conf
    ln -s ~/xuganyu96.github.io/global.gitignore ~/.gitignore
    git config --global core.excludesFile "~/.gitignore"
    git config --global user.name "Ganyu (Bruce) Xu"
    git config --global user.email "xuganyu@berkeley.edu"
    eval "$(ssh-agent -s)" && sleep 1
    ssh-add ~/.ssh/id_rsa
    print_success "Installed xuganyu96.github.io <<<<<<<<<<"
}

install_sys_deps() {
    print_info ">>>>>>>> Installing system dependencies"
    sudo yum update -y
    sudo yum install -y -q git gcc cmake tmux npm clang
    sudo yum groupinstall "Development Tools" -y -q
    sudo yum install -y -q zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel tk-devel \
        libffi-devel xz-devel openssl-devel npm
    print_success "Installed system dependencies <<<<<<<<<<"
}

setup_all() {
    install_sys_deps
    install_personal_config
    setup_docker
    setup_neovim
    setup_pyenv
    setup_rust
}

export -f print_info
export -f print_success
export -f print_warning
export -f install_sys_deps
export -f install_personal_config
export -f setup_docker
export -f setup_neovim
export -f setup_pyenv
export -f setup_rust
export -f setup_all

