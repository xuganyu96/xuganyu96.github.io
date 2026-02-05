# Start with the latest Debian image
FROM debian:latest

ARG GO_VERSION=1.19

RUN apt-get update \
    && apt-get install -y \
        curl \
        wget \
        git \
        sudo \
        gcc \
        g++ \
        clang \
        make \
        cmake \
        ninja-build \
        python3 \
        python3-pip \
        python3-venv \
        zsh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m devbox && \
    echo "devbox ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER devbox
WORKDIR /home/devbox

# Oh-My-Zsh!
RUN sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && sudo chsh -s $(which zsh)

# Code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh \
    && code-server --install-extension vscodevim.vim

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/devbox/.cargo/bin:${PATH}"

# Go
RUN wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
    && sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Expose port for code-server
EXPOSE 8080

# Start code-server with non-privileged user
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none", "project"]
