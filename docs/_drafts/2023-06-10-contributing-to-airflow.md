---
layout: post
title:  "Contributing to Airflow"
date:   2023-06-10 00:00:00
categories: python
---

# Virtual environment setup
I use `pyenv` to manage Python installations and `venv` for managing virtual environment. After cloning repository and creating a branch, I create a virtual environment with:

```
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
```

Something new I learned while setting up this virtual environment is that we can use the `-e` flag with `pip` to install the current project, but with the source code that is in the project. For example, with the issue I want to work on, I don't need any extras, so the command would be:

```
pip install -e .
```

After that, my Python LSP can correctly recognize the packages.