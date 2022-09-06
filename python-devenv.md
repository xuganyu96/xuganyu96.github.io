# Neovim + Python development

## Pyenv
My preferred installation of pyenv is through the [simple GitHub checkout](https://github.com/pyenv/pyenv#basic-github-checkout)

|Common commands||
|:---|:---|
|`global`|Set or show the global Python version(s)|
|`help`|Display help for a command|
|`install`|Install a Python version using python-build|
|`install --list`|List all possible versions; combine with grep to search for specific versions|
|`local`|Set or show the local application-specific Python version(s)|
|`prefix`|Display prefixes for Python versions|
|`rehash`|Rehash pyenv shims (run this after installing executables)|
|`root`|Display the root directory where versions and shims are kept|
|`shell`|Set or show the shell-specific Python version|
|`uninstall`|Uninstall Python versions|
|`version`|Show the current Python version(s) and its origin|
|`versions`|List all Python versions available to pyenv|

## tmux
`tmux` can be installed using `brew install tmux`, then my personalized tmux key bindings can be mapped from [my own repository](https://github.com/xuganyu96/xuganyu96.github.io):

|Common key bind and command|Note|
|:---|:---|
|`ctrl + ?`|List all key binds|
|`ctrl + b`, `-` or `\|` | split the current plane horizontally or vertically |
|`ctrl + b`, `hjkl`|Navigate the panes of a window (left/down/up/right)|
|`ctrl + b`, `c`|Open a new window|
|`ctrl + b`, `,`|Rename a window|
|`ctrl + b`, `[number]`|Jump to window at the specified number|
|`ctrl + b`, `d`|Detach the current session|
|`ctrl + b`, `z`|Toggle full-screen on the current pane|
|`tmux ls`|List active sessions|
|`tmux attach [-t] [name]`|Attach the session with the specified name|
|`tmux new -s [name]`|Open a new session|

## Virtual environment
My choice of virtual environment is Python's `venv`. Once inside the project's root directory, confirm that Python and `pip` versions are correct:

```
python --version
python -m pip --version
```

Instantiate a new virtual environment by specifying the path that will contain all the executables and the libraries. My preference is to set it to `<project root>/.venv`. Activate the virtual environment by sourcing the activation script. Deactivate the virtual environment using the command `deactivate`

```
source .venv/bin/activate
deactivate
```

## Neovim
I want to try Neovim over vanilla Vim because of [this video](https://youtu.be/p0Q3oDY9A5s), but today I ran out of time.
