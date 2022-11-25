# Build the docker image
```bash
docker build -t neovim:latest .
```

To run the container:

```
PROJECTPATH=/path/to/project
docker run -it --rm -v $(pwd):/opt/nvim/project neovim:latest
```

When `nvim` launches for the first time, run `:PackerSync` to install all packages, then quit and launch again.

Your OS still needs to install the NerdFont(s) for icons to work

## Development environment for 
First we will run the container. The container was given a name to facilitate the `docker commit` later:

```bash
docker run -it --rm -v $(pwd):/opt/nvim/project --name pandas_dev neovim:latest
```

Inside the container, install the Neovim plugins, then run the following command to install `mamba` and create the appropriate virtual environment

```
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"  \
    && bash Mambaforge-$(uname)-$(uname -m).sh \
    && source .bashrc \
    && cd project \
    && mamba env create
```

Commit the container back into an image for use later (so we don't have to install mamba repeatedly):

```
docker commit pandas_dev pandas-dev:latest
```

To run it again:

```

```

Inside the container (again), check if things work:

```
mamba activate pandas-dev
python setup.py build_ext -j 4
python -m pip install -e . --no-build-isolation --no-use-pep517
python -c "import pandas; print(pandas.__version__)"
```