# Dockerize Jupyter Notebook on Raspberry Pi 
This guide documents the process by which a Docker image is constructed to run (a very minimal) Jupyter Notebook server on Raspberry Pi 4B running Raspberry Pi OS (formerly Raspbian). 

## Why starting from scratch
When trying to use an existing `jupyter/minimal-notebook` docker image, the following error occurs:
```bash
standard_init_linux.go:211: exec user process caused "exec format error"
```

A quick search on Stack Exchange reveals that this is caused by architecture incompatibility, as the docker image is constructed for an `x86_64` architecture and Raspberry Pi has an ARM processor.

## Base line: Ubuntu, Python 3.7, and Jupyter Notebook installed through `pip3`
```Dockerfile
FROM ubuntu:18.04 

ENV TZ America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV PYTHON_VERSION "3.7"

RUN apt-get update \
    && apt-get install -y \
        vim \
        sudo \
        software-properties-common \
        libffi-dev \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y \
        python${PYTHON_VERSION} \
        python3-pip \
        python${PYTHON_VERSION}-dev \
    && python${PYTHON_VERSION} -m pip install --upgrade --force pip

RUN groupadd -g 501 wslite \
    && useradd -g wslite -u 501 -d /home/wslite wslite \
    && usermod -aG sudo wslite \
    && mkdir /home/wslite \
    && chown -R wslite /home/wslite

RUN pip install jupyter

USER wslite
WORKDIR /home/wslite
ENTRYPOINT ["jupyter", "notebook", "--ip=0.0.0.0"]
```

## What's next?
* Managing user sessions and tokens
* Tighten up securities and performance by putting individual servers behind NginX or something else
* Customizable `requirements.txt`
* Performance monitoring
* State snapshotting
* Kernel in R language
* Running on multiple Raspberry Pis
* Running on Jetson Nano with GPU support
