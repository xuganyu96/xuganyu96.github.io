# docker build -t neovim:latest -f neovim.Dockerfile .
# docker run -it --rm neovim:latest
ARG BASE_IMAGE="python:3.9"
ARG SYSTEM_REQUIREMENTS="sudo gcc curl"
ARG BUILD_REQUIREMENTS="ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen"
ARG NVIM_USER="nvim"
ARG NVIM_HOME_DIR="/home/nvim"

FROM ${BASE_IMAGE}

ARG SYSTEM_REQUIREMENTS
ARG BUILD_REQUIREMENTS
ARG NVIM_USER
ARG NVIM_HOME_DIR

RUN apt-get update \
    && apt-get install -y --no-install-recommends ${SYSTEM_REQUIREMENTS} \
    && apt-get install -y --no-install-recommends ${BUILD_REQUIREMENTS} \
    && apt-get autoremove -yqq --purge \
    && apt-get clean

# Build Neovim from source
RUN git clone https://github.com/neovim/neovim \
    && cd neovim \
    && git checkout stable \
    && make CMAKE_BUILD_TYPE=RelWithDebInfo \
    && make install

# nvim is the less-privileged user
RUN adduser --home ${NVIM_HOME_DIR} \
    --shell "/bin/bash" \
    --disabled-password \
    ${NVIM_USER} \
    && usermod -aG sudo ${NVIM_USER} \
    && echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Update Python tool chain
RUN pip install --upgrade --no-cache-dir pip setuptools wheel

# Below this line are non-root user installations.
USER nvim
WORKDIR ${NVIM_HOME_DIR}

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

# Create XDG_CONFIG_HOME + Personal config + Packer
ENV XDG_CONFIG_HOME=${NVIM_HOME_DIR}/.config
RUN mkdir ${XDG_CONFIG_HOME} \
    && git clone https://github.com/xuganyu96/xuganyu96.github.io.git \
    && ln -s $(pwd)/xuganyu96.github.io/neovim ~/.config/nvim \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim\
         ~/.local/share/nvim/site/pack/packer/start/packer.nvim

ENTRYPOINT ["/bin/bash"]
