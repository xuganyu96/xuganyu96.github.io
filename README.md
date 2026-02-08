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

## Java setup
Download OpenJDK from [here](https://jdk.java.net/23/), then decompress

```bash
curl https://download.java.net/java/GA/jdk23/3c5b90190c68498b986a97f276efd28a/37/GPL/openjdk-23_macos-aarch64_bin.tar.gz -o ~/openjdk23.tar.gz
tar -xvzf openjdk23.tar.gz
rm openjdk23.tar.gz
cd jdk-23.jdk/Contents/Home
echo "export JAVA_HOME=\"$(pwd)\"" >> ~/.zshrc
source ~/.zshrc  # or open a new terminal
javac --version
java --version
```
