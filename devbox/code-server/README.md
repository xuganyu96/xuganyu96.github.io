# Cloud-based IDE
```bash
docker build -t devbox:latest .

docker run -d \
    --name dev-container \
    -v "$(pwd):/home/devbox/project" \
    -e SSH_AUTH_SOCK=/ssh-agent \
    -v ~/.ssh:/ssh-agent \
    -p 8080:8080 \
    devbox:latest
```
