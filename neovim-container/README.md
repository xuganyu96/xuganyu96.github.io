## Build the docker image
```bash
docker build -t neovim:latest .
```

To run the container:

```
docker run -it --rm neovim:latest
```

When `nvim` launches for the first time, run `:PackerSync` to install all packages, then quit and launch again.