---
layout: post
title:  "Pandas development environment setup"
date:   2022-11-20 14:30:00
categories: python
---

I have recently started contributing to `pandas`, a Python data-processing library that I use at work. While the code change I proposed passed all CI tests on GitHub, I am still interested in setting up a working copy of the development environment to better understand what it is like.

It turns out, even for project of only moderate size like `pandas`, the myriad of C library, binaries, and Python package dependnecies are still a nighmare to get right on the first try without using the project's recommended toolchain. I very specifically switched from `conda` to `pyenv`, so it is a real pain to have to use `mamba`, which uses `conda` undernead the hood. Within 2 hours, I did manage to get the whole thing to work, but my distaste of `conda` eventually got me to uninstall `mamba` and give the progress I have made.

Note that this is done on an 2020 M1 Macbook Air with MacOS Ventura (so `brew`'s home directory is `/opt/homebrew`). Python is installed and managed through pyenv 2.3.4.

# Virtual environment

```
python -m venv .venv
```

The `.gitignore` file on the `pandas-dev/pandas` repository does not exclude `.venv` (although GitHub's template will). Without modifying `.gitignore` of the repository, the workaround I found was to use a global `.gitignore`, which can then be synced across computers through GitHub.

# Install python dependencies
```bash
pip install --upgrade pip wheel setuptools
pip install -r requirements
```

## Installing `psycopg2` from source:
First problem: `psycopg2` cannot be installed because it could not find `pg_config` binary.

```
Collecting psycopg2
  Using cached psycopg2-2.9.5.tar.gz (384 kB)
  Preparing metadata (setup.py) ... error
  error: subprocess-exited-with-error

  × python setup.py egg_info did not run successfully.
  │ exit code: 1
  ╰─> [25 lines of output]
      /Users/ganyuxu/Documents/projects/pandas/.venv/lib/python3.10/site-packages/setuptools/config/setupcfg.py:508: SetuptoolsDeprecationWarning: The license_file parameter is deprecated, use license_files instead.
        warnings.warn(msg, warning_class)
      running egg_info
      creating /private/var/folders/92/rxm5_d4n50ddj3y4xzl8s2700000gn/T/pip-pip-egg-info-v5njs25m/psycopg2.egg-info
      writing /private/var/folders/92/rxm5_d4n50ddj3y4xzl8s2700000gn/T/pip-pip-egg-info-v5njs25m/psycopg2.egg-info/PKG-INFO
      writing dependency_links to /private/var/folders/92/rxm5_d4n50ddj3y4xzl8s2700000gn/T/pip-pip-egg-info-v5njs25m/psycopg2.egg-info/dependency_links.txt
      writing top-level names to /private/var/folders/92/rxm5_d4n50ddj3y4xzl8s2700000gn/T/pip-pip-egg-info-v5njs25m/psycopg2.egg-info/top_level.txt
      writing manifest file '/private/var/folders/92/rxm5_d4n50ddj3y4xzl8s2700000gn/T/pip-pip-egg-info-v5njs25m/psycopg2.egg-info/SOURCES.txt'

      Error: pg_config executable not found.

      pg_config is required to build psycopg2 from source.  Please add the directory
      containing pg_config to the $PATH or specify the full executable path with the
      option:

          python setup.py build_ext --pg-config /path/to/pg_config build ...

      or with the pg_config option in 'setup.cfg'.

      If you prefer to avoid building psycopg2 from source, please install the PyPI
      'psycopg2-binary' package instead.

      For further information please check the 'doc/src/install.rst' file (also at
      <https://www.psycopg.org/docs/install.html>).

      [end of output]

  note: This error originates from a subprocess, and is likely not a problem with pip.
error: metadata-generation-faile
```

Solution? Install PostgreSQL through brew, then either add the installation path to `PATH` or create a symlink to the `pg_config` stuff.

`brew install postgresql` will work, but I want to try something lighter-weight since I don't need the server-side things.

```
brew install libpq
PATH="/opt/homebrew/Cellar/libpq/15.1/bin:${PATH}" pip install -r requirements-dev.txt
```

## Installing `table`
I am also missing something related to `HDF5`, which stopped me from installing `tables==3.7.0`

```
Collecting tables
  Downloading tables-3.7.0.tar.gz (8.2 MB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 8.2/8.2 MB 57.6 MB/s eta 0:00:00
  Installing build dependencies ... done
  Getting requirements to build wheel ... error
  error: subprocess-exited-with-error

  × Getting requirements to build wheel did not run successfully.
  │ exit code: 1
  ╰─> [12 lines of output]
      /var/folders/92/rxm5_d4n50ddj3y4xzl8s2700000gn/T/H5closesyfucpba.c:2:5: error: implicit declaration of function 'H5close' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
          H5close();
          ^
      1 error generated.
      cpuinfo failed, assuming no CPU features: No module named 'cpuinfo'
      * Using Python 3.10.4 (main, Apr 20 2022, 23:51:46) [Clang 13.1.6 (clang-1316.0.21.2.3)]
      * Found cython 0.29.32
      * USE_PKGCONFIG: False
      .. ERROR:: Could not find a local HDF5 installation.
         You may need to explicitly state where your local HDF5 headers and
         library can be found by setting the ``HDF5_DIR`` environment
         variable or by using the ``--hdf5`` command-line option.
      [end of output]

  note: This error originates from a subprocess, and is likely not a problem with pip.
error: subprocess-exited-with-error

× Getting requirements to build wheel did not run successfully.
│ exit code: 1
╰─> See above for output.

note: This error originates from a subprocess, and is likely not a problem with pip
```

First try brew:

```
brew install hdf5
```

Need to specify another path:

```
HDF5_DIR=/opt/homebrew/Cellar/hdf5/1.12.2_2 \
    PATH="/opt/homebrew/Cellar/libpq/15.1/bin:${PATH}" \
    pip install -r requirements-dev.txt
```

## `boto3` and `botocore` version pinning
`pip` taking too much time resolving dependency seems to be a [known issue](https://stackoverflow.com/questions/65122957/resolving-new-pip-backtracking-runtime-issue) called [backtracking](https://pip.pypa.io/en/latest/topics/dependency-resolution/).

Installing `boto3` and `botocore` ahead of time doesn't work.

## `fiona` and its library dependencies
In trying to install `fiona==1.8.22` I ran into this error message:

```
Collecting fiona>=1.8
  Downloading Fiona-1.8.22.tar.gz (1.4 MB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 1.4/1.4 MB 53.9 MB/s eta 0:00:00
  Preparing metadata (setup.py) ... error
  error: subprocess-exited-with-error

  × python setup.py egg_info did not run successfully.
  │ exit code: 1
  ╰─> [2 lines of output]
      Failed to get options via gdal-config: [Errno 2] No such file or directory: 'gdal-config'
      A GDAL API version must be specified. Provide a path to gdal-config using a GDAL_CONFIG environment variable or use a GDAL_VERSION environment variable.
      [end of output]

  note: This error originates from a subprocess, and is likely not a problem with pip.
error: metadata-generation-failed

× Encountered error while generating package metadata.
╰─> See above for output.

note: This is an issue with the package mentioned above, not pip
```

again, try `brew` first:

```
brew install gdal
```

After installation, the problem was resolved.

## Giving up
After resolving the problems above, I still ran into additional problems with `psycopg2` and `brotlipy`... At this point I have sunk 2 hours into running `pip install -r requirements.txt` with still the "build" and "install" parts ahead of me. The risk of messing up my laptop feels unworthy of the reward I can get, so I will pivot to using a different method for setting up the development environment.

# Using Mamba
Thanks to Apple putting a measly 8GB of RAM on the MacBook Air I can't afford to run Docker (which I will use as a last resort, but which will also require me to use a beefier laptop). Will try `mamba` as recommended by [pandas' own website](https://pandas.pydata.org/docs/dev/development/contributing_environment.html#option-1a-using-mamba-recommended)

First you need to install `mamba` using the [installation script](https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-MacOSX-arm64.sh), then from the project root:

```
# Create and activate the build environment
mamba env create
mamba activate pandas-dev

# Build and install pandas
python setup.py build_ext -j 4
python -m pip install -e . --no-build-isolation --no-use-pep517

# Verify build
python -c "import pandas; print(pandas.__version__);"
```

This all works, but it overrides my `pyenv` installation, which I don't like. 

```
rm -rf /Users/ganyuxu/mambaforge
```

I would rather use Docker and VSCode than letting unfamiliar virtual environment mess with my laptop.

# Conclusion
1. It would be great if there can be some way to only install a small portion of the dependencies
2. `pip` needs to get its dependency resolver fixed
3. Maybe I should think about using Codespace or GitPod, but I don't like VSCode, and the vim plugin on VSCode just won't do it. Maybe I should consider doing a project where I can have Neovim in a container...