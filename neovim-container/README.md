# Neovim in a box

## Quick start
From this directory `/xuganyu96.github.io/neovim-container`, run:

```bash
docker build -t neovim:latest .
```

After the build completes, launch the container:

```bash
docker run -it --name neovim neovim:latest
```

From within the container, launch `nvim` and execute `PackerSync`. Exit the container, and commit the file change into the docker image:

```bash
docker commit neovim neovim:latest
docker container rm neovim  # cleanup stopped containers
```

Now I can spawn containers with Neovim fully configured:

```bash
docker run -it --rm --name neovim neovim:latest
```

## Example: development environment for pandas
First we will run the container. The container was given a name to facilitate the `docker commit` later:

```bash
# from pandas project root
docker run -it -v $(pwd):/home/nvim/pandas --name pandas_dev neovim:latest
```

Run the following command to install `mamba` and create the appropriate virtual environment

```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"  \
    && bash Mambaforge-$(uname)-$(uname -m).sh \
    && source .bashrc \
    && cd pandas \
    && mamba env create
```

Exit the container, then commit the container into an image for subsequent uses (so we don't have to install mamba repeatedly):

```bash
docker commit pandas_dev pandas-dev:latest
docker container rm pandas_dev  # cleanup stopped container
```

To run it again:

```bash
# from pandas project root
docker run -it --rm -v $(pwd):/home/nvim/pandas --name pandas_dev pandas-dev:latest
```

Inside the container (again), check if things work:

```bash
cd pandas \
&& mamba activate pandas-dev \
&& python setup.py build_ext -j 4 \
&& python -m pip install -e . --no-build-isolation --no-use-pep517 \
&& python -c "import pandas; print(pandas.__version__)"
```