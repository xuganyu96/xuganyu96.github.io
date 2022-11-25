## Build the docker image
```bash
docker build -t neovim:latest .
```

To run the container:

```
PROJECTPATH=/path/to/project
docker run -it --rm -v ${PROJECTPATH}:/opt/nvim/project neovim:latest
```

When `nvim` launches for the first time, run `:PackerSync` to install all packages, then quit and launch again.

Your OS still needs to install the NerdFont(s) for icons to work