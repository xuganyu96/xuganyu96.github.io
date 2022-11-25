---
layout: post
title:  "Pandas development environment setup, the sequel"
date:   2022-11-25 11:30:00
categories: python container
---

About a week ago I attempted to set up a complete development environment for [pandas](https://github.com/pandas-dev/pandas) by following [this guidance](https://pandas.pydata.org/docs/dev/development/contributing_environment.html). Three approaches were listed on the guide, but each of them has some flaws that I found unacceptable: the mamba approach requires installing mamba on my laptop, the pip approach requires installing large number of additional C libraries and configuring them into the right paths, and the docker approach only supports development using VSCode. I don't like mamba (which is built on top of conda) because I specifically switched from conda to pyenv, I don't want to risk breaking my development setup for other projects by tinkering with external libraries that I don't quite understand, and I don't want to use VSCode.

At the same time, I was also hatching an idea about making my Neovim setup more portable using containers. My idea at the time was to build a Docker image that has Neovim binaries, my configurations, and the language servers, so that I can run a single `docker run` command and have my complete setup ready to go.

Putting two and two together, I figured that building my own `Neovim` image was a promising lead. This blog post details the steps I took to build a working `pandas` development environment with Neovim.

# Neovim
I chose to work with a Debian base image (more precisely `python:3.9`, which was based on `debian:buster`), but for reasons beyond my understanding, `apt-get install neovim` will install version v0.4, while at the time of writing this post, the latest stable version is v0.8.

So I chose to build Neovim from source, which resulted in the following Dockerfile section:

```Dockerfile
# Note that this was run as "root" so that 
RUN git clone https://github.com/neovim/neovim \
    && cd neovim \
    && git checkout stable \
    && make CMAKE_BUILD_TYPE=RelWithDebInfo \
    && make install
```

Building and installing Neovim from source took around 3 minutes on a 6-core Intel 16-inch MacBook pro, although after the initial build, this layer should have been cached, so subsequent build should be very fast.

## Non-root user
Per best practice, a non-root user is created. Below are the commands I ran to setup an grant `sudo` privilege to the non-root user. note that `NVIM_HOME_DIR` and `NVIM_USER` are both build arguments declared using the `ARG` keyword.

```Dockerfile
RUN adduser --home ${NVIM_HOME_DIR} \
    --shell "/bin/bash" \
    --disabled-password \
    ${NVIM_USER} \
    && usermod -aG sudo ${NVIM_USER} \  # grant sudo privilege
    && echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers  # invoke sudo without password
```

## Language servers
I chose to let language servers be installed by non-root users (although some of the steps did require root-level access, which is why `sudo` was granted to the non-root user).

```Dockerfile
# pyright language server
RUN sudo apt-get install -y nodejs npm \
    && sudo npm install -g pyright

# rust-analyzer, which I choose to isntall through rustup
ENV PATH="${NVIM_HOME_DIR}/.cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o ./rustup.sh \
    && sh ./rustup.sh -y \
    && rm ./rustup.sh \
    && rustup component add rust-analyzer \
    && sudo ln -s $(rustup which --toolchain stable rust-analyzer) /usr/local/bin/rust-analyzer
```

## Personal configuration
Finally with all external dependencies fulfilled, I am ready to put in my personal configuration:

```Dockerfile
# Create XDG_CONFIG_HOME + Personal config + Packer
ENV XDG_CONFIG_HOME=${NVIM_HOME_DIR}/.config
RUN mkdir ${XDG_CONFIG_HOME} \
    && git clone https://github.com/xuganyu96/xuganyu96.github.io.git \
    && ln -s $(pwd)/xuganyu96.github.io/neovim ~/.config/nvim \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim\
         ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

However, this only copies the configuration files and `Packer`, while the plugins listed in the configuration files are not installed. Unfortunately I could not figure out a way to invoke the `PackerSync` command from the build stage, so running the container to execute `PackerSync` from within Neovim is the only option.

Fortunately, there is still a way out using `docker commit`. This is not the most elegant solution, but with `docker commit` I will only need to call `PackerSync` once per machine (provided that I will not use Dockerhub; if I upload the image to DockerHub that I will only need call `PackerSync` per build). Here is how it is done:

First build the current Dockerfile, without Neovim plugins installed

```bash
# from Dockerfile's directory
docker build -t neovim:latest .
```

Then, launch the container. Give the container a name for simplier reference later:

```bash
docker run -it --name "neovim" neovim:latest  # don't add --rm flag
```

From within the container, launch `nvim` to execute `PackerSync`. Exit neovim and quit out of the container. The container should be stopped but not removed (you can check that the container is not removed using `docker ps -a`).

The `PackerSync` command will download all the necessary plugin source code, and the container's file system is still preserved (sorry I don't quite have the intimate knowledge of how file changes were preserved there). At this point, we can call `docker commit` to add the plugin files into the docker image:

```bash
docker commit neovim neovim:latest
```

Finally, clean up the first container:

```bash
docker container rm neovim
```

# Pandas
With Neovim, personal configs, plugins, language servers, and Python (comes with the base image!) all good to go, setting up the tool chain for `pandas` development is fairly straightforward:

1. Install mamba
2. Create virtual environment
3. Enter virtual environment
4. Build pandas from source
5. Start working

step 1 and 2 are purely file changes, so we can use the `docker commit` trick to preserve them. There are two reasons why I didn't put them in the `Dockerfile`:

1. I want the `Dockerfile` to not be specific to any project
2. The headless execution of mamba's installation scrtip is tedious work

## Setting up the toolchain
Navigate to the `pandas` repository, then run the `neovim:latest` image with the repository mounted into the container:

```bash
# from pandas project root
docker run -it --rm --name "pandas_dev" -v $(pwd):/home/nvim/pandas neovim:latest
```

```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"  \
    && bash Mambaforge-$(uname)-$(uname -m).sh \
    && source .bashrc \
    && cd pandas \
    && mamba env create
```

I will commit the container into a separate image tagged `pandas-dev:latest`:

```bash
docker commit pandas_dev pandas-dev:latest
```

## Validating the commit
Launch the container again, this time with the image we committed from the step above

```bash
# from pandas project root
docker run -it --rm --name "pandas_dev" -v $(pwd):/home/nvim/pandas pandas-dev:latest
```

then navigate into the `pandas` project, activate virtual environment, build the project, and attempt to import

```bash
cd pandas \
&& mamba activate pandas-dev \
&& python setup.py build_ext -j 4 \
&& python -m pip install -e . --no-build-isolation --no-use-pep517 \
&& python -c "import pandas; print(pandas.__version__)"
```
