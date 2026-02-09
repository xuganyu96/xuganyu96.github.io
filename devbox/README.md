# Dev box
- the `run.sh` script will copy SSH credentials and setup script, then run the setup script
- SSH into the instance, including using port forwarding to access code-server on `localhost:8080`

```bash
export REMOTE_USER="..." PEM_PATH="..."
export REMOTE_HOST="..."
./run.sh
```

## Code server
[code-server](./code-server) can be built as a containerized development environment.
It has Python, Rust, and Go built in, and the container can be built separately from the rest of the devbox.

```bash
# First build the image
docker build \
    -t devbox:latest \
    -f code-server/Dockerfile \
    code-server

# Run the image, mounting the current directory into /home/devbox/project
docker run -d \
    --rm \
    --name dev-container \
    -v $(pwd):/home/devbox/project \
    -v ~/.ssh:/home/devbox/.ssh \
    -p 8080:8080 \
    devbox:latest
```

Some limitations:
- The `rust-analyzer` extension in Open VSX does not support Rust 2024 Edition
