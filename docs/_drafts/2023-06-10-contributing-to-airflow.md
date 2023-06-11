---
layout: post
title:  "Contributing to Airflow"
date:   2023-06-10 00:00:00
categories: python
---

Recently I raised a [feature request](https://github.com/apache/airflow/issues/31818) on the `apache/airflow` project, and after the core maintainers gave it the informal blessing, I decided to implement the feature and get myself inducted into the list of contributors to Apache Airflow. This blog post documents the development process, which is substantial as Airflow is an equally substantial project with many moving parts, and I want to try GitHub's code space for the first time.

Starting a code space is simple enough. In addition, there are existing dev containers configurations set by the code base, so that is where we will start. Something that I initially found comfusing but later understood was that the terminal inside the code space VSCode instance is a shell into the dev container that runs this instance of `code-server`.

The dev container uses `/var/run/docker.sock` to execute calls to the Docker engine, which how `breeze` can spin up Airflow cluster for testing purposes. We will get to that later.

When the codespace instance first starts, the terminal defaults to the `root` user (why?). I guess we can make do with it for now, but I am sure that sooner than later we will find using `root` to be a bad idea and revert course.

## Setting up the Python environment
The container is spawned from GitHub's own image `ghcr.io/apache/airflow/main/ci/python3.8`, so we will use the Python 3.8 installed there. Begin with the standard stuff:

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
```

Then we use `setup.py` to install the local copy of `airflow`:

```bash
pip install --no-cache -e ".[devel]"
```

Next we will need to install and configure `breeze`:

```bash
pip install pipx
pipx ensurepath
pipx install -e ./dev/breeze
```

Before we can run `breeze`, we need to install `docker-compose`, is not shipped with this dev container by default:

```bash
sudo apt update
sudo apt upgrade
# NOTE: the latest version at the time of writing this post is 1.28.1, but it could change
curl -L "https://github.com/docker/compose/releases/download/2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmox +x /usr/local/bin/docker-compose
docker-compose --version

breeze
```

At this point, the codespace instance crashed. My guess is that the instance is out of memory.