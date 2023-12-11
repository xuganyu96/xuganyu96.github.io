#!/bin/bash

# ***********  README  **********
# This script installs the sets up the development dependencies
# After the EC2 instance launches, use scp to copy this script to the remote environment
# >> REMOTE_HOST="your.hostname.amazon.com"
# >> REMOTE_USER="ec2-user"
# >> PEM_PATH="/path/to/key"
# >> scp -i $PEM_PATH ./amazon-linux-setup.sh ${REMOTE_USER}@${REMOTE_HOST}:/home/ec2-user/setup.sh
# >> ssh -i $PEM_PATH ${REMOTE_USER}@${REMOTE_HOST}
# *******************************

sudo yum update -y
sudo yum install -y git gcc cmake tmux npm
sudo yum groupinstall "Development Tools" -y
sudo yum install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel tk-devel \
	libffi-devel xz-devel openssl-devel npm

# Add id_rsa.pub to authorized_keys for subsequent logins
echo "Copy your local RSA public key:"
echo ">> cat ~/.ssh/id_rsa.pub | pbcopy"
echo "Paste it here:"
read rsa_pubkey
echo $rsa_pubkey >> ~/.ssh/authorized_keys
echo "local RSA public key added to keyless login"

# Generate new SSH key pair for GitHub
ssh-keygen -t rsa -b 4096 \
	-f ~/.ssh/id_rsa \
	-C "xugany96@gmail.com" \
	-N ""  # empty passphrase is okay
echo "Add your new key to https://github.com/settings/keys >>>>>>>>>"
cat ~/.ssh/id_rsa.pub
echo "<<<<<<<<< Press Enter when done"
read

# Personal dotfiles
git clone git@github.com:xuganyu96/xuganyu96.github.io.git
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

# Docker
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo docker run --rm hello-world
echo "Finished installing Docker."
echo "Please log out and log back in to use Docker without sudo"
echo -n "Press ENTER to continue: "; read
echo

# Neovim
git clone --depth 1 git@github.com:neovim/neovim.git  # shallow clone for better performance
cd neovim
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
nvim --headless -c ":MasonInstall rust-analyzer --force" -c "qall"
nvim --headless -c ":MasonInstall pyright --force" -c "qall"
nvim --headless -c ":MasonInstall dockerfile-language-server --force" -c "qall"
nvim --headless -c ":MasonInstall bash-language-server --force" -c "qall"
nvim --headless -c ":MasonInstall clangd --force" -c "qall"
cd ~

# pyenv
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
cd ~/.pyenv && src/configure && make -C src
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
source ~/.bashrc
pyenv install 3.10.13 --verbose
pyenv global 3.10.13
python -m pip install --upgrade pip setuptools wheel

# Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source ~/.cargo/env

# Code server
# TODO: maybe code-server is also a good idea

pubipv4=$(curl http://checkip.amazonaws.com)
echo ">>>> Setup finished. Please log off and log back in using the command: <<<<"
echo ">> ssh ec2-user@${pubipv4}"

