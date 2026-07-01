---
layout: post
title:  Server monitoring with Beszel
---

<!-- TODO: redact tailee7580.ts.net -->

I want to know:

- CPU, RAM, Disk, and Network usage on my main server and backup server

## Test run

Start with running the hub and the agent as standalone containers. In the final
production setup, the system on which Beszel Hub runs will also be monitored
with a Beszel agent. On this system, the agent will communicate with the hub
using a UNIX socket. On the backup systems, the agent will communicate with the
hub using network connection.

```bash
mkdir -p ~/Shared/SelfHosting/beszel/beszel_data
mkdir -p ~/Shared/SelfHosting/beszel/beszel_agent_data
mkdir -p ~/Shared/SelfHosting/beszel/beszel_socket

docker run -d --rm \
    --name "beszel" \
    -e "APP_URL=https://thinkcentre.tailee7580.ts.net:8090" \
    -p 8090:8090 \
    -u 1000:1000 \
    -v $HOME/Shared/SelfHosting/beszel/beszel_data:/beszel_data \
    -v $HOME/Shared/SelfHosting/beszel/beszel_socket:/beszel_socket \
    henrygd/beszel:latest
```

Inspect the container's log messages with `docker logs -f beszel`, then visit
<http://thinkcentre.tailee7580.ts.net:8090> using a browser, which should show
a screen for creating the admin account. After logging in, we should see an
empty dashboard. Click "Add System" and copy the docker run command, though
there are a few items to modify:

- The agent will listen to the socket at `/beszel_socket/beszel.sock`, so that's
  what the server will reach out to, too.

```bash
docker run -d \
    --name beszel-agent \
    --network host \
    -e KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKfaWhPRmUsGcsn9l56wLIKH46k6IYHYzUz3TYmrFm3P" \
    -e LISTEN=/beszel_socket/beszel.sock \
    -e TOKEN="14653-d376998a5-c7eb-9c5010d64" \
    -e HUB_URL="http://thinkcentre.tailee7580.ts.net:8090" \
    -u 1000:1000 \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v $HOME/Shared/SelfHosting/beszel/beszel_docket:/beszel_socket \
    -v $HOME/Shared/SelfHosting/beszel/beszel_agent_data:/var/lib/beszel-agent \
    henrygd/beszel-agent:latest
```

After the agent container starts running, its logs will complain that websocket
connection to the hub URL returns error code 401. This is because the hub has
not yet added the agent instance. After Adding the instance, the agent container
should log `"INFO: WebSocket connected"`, and system information should show up
on the hub website. This concludes the test run, and we can clean up:

```bash
docker stop beszel beszel-agent
```
