# docker build -t neovim:latest -f neovim.Dockerfile .
# docker run -it --rm neovim:latest
ARG PYTHON_BASE_IMAGE="python:3.9"
ARG SYSTEM_REQUIREMENTS="sudo gcc netcat curl gnupg2 dnsutils default-libmysqlclient-dev default-mysql-client libpq-dev make jq postgresql-client"
ARG BUILD_REQUIREMENTS="ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen"
ARG NVIM_GID="501"
ARG NVIM_HOME_DIR="/opt/nvim"
ARG NVIM_UID="501"

FROM ${PYTHON_BASE_IMAGE}

ARG NVIM_GID="501"
ARG NVIM_HOME_DIR="/opt/nvim"
ARG NVIM_UID="501"
ARG PYTHON_BASE_IMAGE
ARG SYSTEM_REQUIREMENTS
ARG BUILD_REQUIREMENTS

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


# NodeJS, npm, and PyRight language server
RUN sudo apt-get install -y nodejs npm \
    && sudo npm install -g pyright

# nvim is the less-privileged user
RUN groupadd -g ${NVIM_GID} nvim \
    && useradd -g nvim -u ${NVIM_UID} -d ${NVIM_HOME_DIR} nvim \
    && usermod -aG sudo nvim \
    && mkdir ${NVIM_HOME_DIR} \
    && mkdir ${NVIM_HOME_DIR}/.config \
    && chown -R nvim: ${NVIM_HOME_DIR} /usr/local

USER nvim
WORKDIR ${NVIM_HOME_DIR}
ENV XDG_CONFIG_HOME=${NVIM_HOME_DIR}/.config

RUN pip install --upgrade --no-cache-dir pip setuptools wheel

# Rust toolchain
ENV PATH="${NVIM_HOME_DIR}/.cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o ./rustup.sh \
    && sh ./rustup.sh -y \
    && rm ./rustup.sh \
    && rustup component add rust-analyzer \
    && ln -s $(rustup which --toolchain stable rust-analyzer) /usr/local/bin/rust-analyzer

# Personal config + Packer
RUN git clone https://github.com/xuganyu96/xuganyu96.github.io.git \
    && ln -s $(pwd)/xuganyu96.github.io/neovim ~/.config/nvim \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim\
         ~/.local/share/nvim/site/pack/packer/start/packer.nvim

ENTRYPOINT ["/bin/bash"]
