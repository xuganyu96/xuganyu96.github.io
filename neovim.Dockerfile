# docker build -t neovim:latest -f neovim.Dockerfile .
# docker run -it neovim:latest
ARG PYTHON_BASE_IMAGE="python:3.9"
ARG SYSTEM_REQUIREMENTS="gcc netcat curl gnupg2 dnsutils default-libmysqlclient-dev default-mysql-client libpq-dev make jq postgresql-client neovim"
ARG NVIM_GID="501"
ARG NVIM_HOME_DIR="/opt/nvim"
ARG NVIM_UID="501"

FROM ${PYTHON_BASE_IMAGE}

ARG NVIM_GID="501"
ARG NVIM_HOME_DIR="/opt/nvim"
ARG NVIM_UID="501"
ARG PYTHON_BASE_IMAGE
ARG SYSTEM_REQUIREMENTS

RUN apt-get update \
    && apt-get install -y --no-install-recommends ${SYSTEM_REQUIREMENTS} \
    && apt-get autoremove -yqq --purge \
    && apt-get clean

RUN groupadd -g ${NVIM_GID} nvim \
    && useradd -g nvim -u ${NVIM_UID} -d ${NVIM_HOME_DIR} nvim \
    && mkdir ${NVIM_HOME_DIR} \
    && chown -R nvim: ${NVIM_HOME_DIR} /usr/local

USER nvim
WORKDIR ${NVIM_HOME_DIR}

RUN pip install --upgrade --no-cache-dir pip setuptools wheel

ENTRYPOINT ["/bin/bash"]
