# Dev box
- the `run.sh` script will copy SSH credentials and setup script, then run the setup script
- SSH into the instance, including using port forwarding to access code-server on `localhost:8080`

```bash
export REMOTE_USER="..." PEM_PATH="..."
export REMOTE_HOST="..."
./run.sh
ssh -i ${PEM_PATH} \
    -N -L 8080:${REMOTE_HOST}:8080 \
    ${REMOTE_USER}@${REMOTE_HOST}
```
