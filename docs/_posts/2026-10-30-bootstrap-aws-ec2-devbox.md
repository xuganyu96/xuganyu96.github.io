---
layout:     post
title:      Bootstrapping AWS EC2 Devbox
date:       2026-10-30 14:50:41 -0400
categories: miscellaneous
---

I want to write a shell script that sets up an AWS EC2 instance running Amazon Linux
2023 for remote development works. For now I will work with x86_64, but later I might
want to extend into aarch64. For developing this script, I will use a `c7i.large`
instance, which as 2 virtual cores and 4 GiB of RAM.

After the instance launches, grab the public IPv4 (or the public DNS record), and
add to the local SSH config:

```text
Host aws-ec2-devbox
    HostName <public IPv4 or public DNS record>
    IdentityFile /path/to/private/key.pem
    User <usually ec2-user>
    RequestTTY force
```

At the time of writing this script, Amazon Linux 2023 ships with curl and wget, so
bootstrapping can be as straightforward as downloading the script and executing it.

```bash
curl https://xuganyu96.github.io/assets/aws-bootstrap.sh | sh -s 
```

First, I want this script to be idempotent. This will be implemented by leaving a
short log file at `$HOME/.bootstrap/log.txt`. If this file exists, then print this
file, else run the bootstrapping steps.

```bash
BOOTSTRAP_LOG_PATH="${HOME}/.bootstrap.log"

if [ -f ${BOOTSTRAP_LOG_PATH} ]; then
  cat ${BOOTSTRAP_LOG_PATH}
  exit 1
fi

echo "Bootstrapping last finished: $(date)" >> ${BOOTSTRAP_LOG_PATH}
```

The bottom layer of bootstrapping is the system packages. With Amazon Linux, `dnf`
is the default package manager. Notably, Docker is installed with dnf, unlike with
Fedora Workstation edition, where I need to [manage external rpm repository](https://docs.docker.com/engine/install/fedora/).

```bash
sudo dnf update -y \
    && sudo dnf install -y git docker gcc clang cmake nodejs npm lldb \
    && sudo dnf groupinstall -y "Development Tools" \
    && sudo dnf install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite \
        sqlite-devel tk-devel libffi-devel xz-devel openssl-devel ninja-build \
        valgrind-devel \
    && sudo systemctl enable docker \
    && sudo systemctl start docker \
    && sudo usermod -aG docker "$USER" \
    && sudo docker run hello-world \
    && sudo chsh -s $(which zsh) $USER
```

Amazon Linux ships bash by default. I want to switch to zsh and install Oh My Zsh:

```bash
sudo dnf install -y zsh util-linux-user
sudo chsh -s $(which zsh) $USER
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Next, I use tmux with my custom config. My config will display a red status bar indicating
tmux is running on remote. It is generally recommended to not nest tmux inside tmux.

```bash
sudo dnf install -y tmux \
    && wget -O ~/.tmux.conf \
        https://raw.githubusercontent.com/xuganyu96/xuganyu96.github.io/refs/heads/main/tmux.conf
```

I use a custom global gitignore:

```bash
wget -O ~/.gitignore https://raw.githubusercontent.com/xuganyu96/xuganyu96.github.io/refs/heads/main/global.gitignore \
    && git config --global core.excludesFile "~/.gitignore"
```

Last of the essential tools is Neovim:

```bash
curl -fLO https://github.com/neovim/neovim/releases/download/v0.11.7/nvim-linux-x86_64.tar.gz \
    && sudo rm -rf /opt/nvim-linux-x86_64 \
    && sudo tar -C /opt -xzvf nvim-linux-x86_64.tar.gz \
    && echo 'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"' >> ~/.zshrc \
    && mkdir -p ~/.config/nvim
    && wget -O ~/.config/nvim/init.lua \
        https://raw.githubusercontent.com/xuganyu96/xuganyu96.github.io/refs/heads/main/neovim/init.lua
```

The system packages already installed my C programming tool chain. I also program
Python and Rust. For Python, I will install pyenv but stop before installing specific
interpreter. For Rust, the installer script can just go brrr.

```bash
git clone https://github.com/pyenv/pyenv.git ~/.pyenv \
    && cd ~/.pyenv && src/configure && make -C src \
    && echo '# [pyenv]' >> ~/.zshrc \
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc \
    && echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc \
    && echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc \

curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && source ~/.cargo/env \
    && cargo install ripgrep
```

The complete script can be found at [`assets/aws-bootstrap.sh`](/assets/aws-bootstrap.sh).
