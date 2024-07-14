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

## AWS setup
- Setup the environment variables
- Copy the setup script to remote
- SSH into the remote and run the setup script
- Log out, then log in again

```bash
PEM_PATH="/path/to/key"
REMOTE_USER="ec2-user"
REMOTE_HOST="your.hostname.amazon.com"
scp -i ${PEM_PATH} ./amazon-linux-setup.sh ${REMOTE_USER}@${REMOTE_HOST}:/home/ec2-user/setup.sh
ssh -i ${PEM_PATH} ${REMOTE_USER}@${REMOTE_HOST}

./setup.sh  # takes about 13 minutes on t3.medium
```

TODO's:
- [ ] Install `neovim` from `yum` instead of compiling it from source
- [ ] Trim down the system requirements from `yum install ...`