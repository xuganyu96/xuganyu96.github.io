---
layout: post
title:  Server monitoring with Beszel
date: 2026-07-01 12:21:12 -0400
---

I want to know CPU, RAM, disk, and network usage on my main server and backup
servers.

## Test run

Start with running the hub and the agent as standalone containers. In the final
production setup, the system on which Beszel Hub runs will also be monitored
with a Beszel agent. On this system, the agent will communicate with the hub
using a UNIX socket. On the backup systems, the agent will communicate with the
hub using a network connection.

```bash
mkdir -p ~/Shared/SelfHosting/beszel/beszel_data
mkdir -p ~/Shared/SelfHosting/beszel/beszel_agent_data
mkdir -p ~/Shared/SelfHosting/beszel/beszel_socket

docker run -d --rm \
    --name "beszel" \
    -e "APP_URL=https://thinkcentre.<REDACTED>.ts.net:8090" \
    -p 8090:8090 \
    -u 1000:1000 \
    -v $HOME/Shared/SelfHosting/beszel/beszel_data:/beszel_data \
    -v $HOME/Shared/SelfHosting/beszel/beszel_socket:/beszel_socket \
    henrygd/beszel:latest
```

Inspect the container's log messages with `docker logs -f beszel`, then visit
<http://thinkcentre.REDACTED.ts.net:8090> using a browser, which should show
a screen for creating the admin account. After logging in, we should see an
empty dashboard. Click "Add System" and copy the docker run command, though
there are a few items to modify:

- The agent will listen to the socket at `/beszel_socket/beszel.sock`, so that's
  what the server will reach out to, too.

```bash
docker run -d \
    --name beszel-agent \
    --network host \
    -e KEY="<REDACTED>" \
    -e LISTEN=/beszel_socket/beszel.sock \
    -e TOKEN="<REDACTED>" \
    -e HUB_URL="http://thinkcentre.<REDACTED>.ts.net:8090" \
    -u 1000:1000 \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v $HOME/Shared/SelfHosting/beszel/beszel_socket:/beszel_socket \
    -v $HOME/Shared/SelfHosting/beszel/beszel_agent_data:/var/lib/beszel-agent \
    henrygd/beszel-agent:latest
```

After the agent container starts running, its logs will complain that websocket
connection to the hub URL returns error code 401. This is because the hub has
not yet added the agent instance. After adding the instance, the agent container
should log `"INFO: WebSocket connected"`, and system information should show up
on the hub website. This concludes the test run, and we can clean up:

```bash
docker stop beszel beszel-agent
docker rm beszel beszel-agent
```

## Hooking up the hub with Caddy

<https://beszel.dev> has an example Caddyfile directive for Beszel hub. We just
need to modify it for our compose setup.

```caddyfile
beszel.thinkcentre.<MY_DOMAIN> {
	request_body {
		max_size 10MB
	}
	reverse_proxy beszel:8090 {
		transport http {
			read_timeout 360s
		}
	}
}
```

We will also add the section for Beszel hub and the agent. In my setup, the
`docker-compose.yml` file will be committed to public repository, so `KEY`,
`TOKEN`, and other sensitive credentials will need to go into an environment
file:

```yaml
services:
  beszel:
    image: henrygd/beszel:latest
    restart: unless-stopped
    networks:
      - homelab
    environment:
      - APP_URL=https://beszel.thinkcentre.<MY_DOMAIN>
    user: "1000:1000"
    volumes:
      - ${HOME}/Shared/SelfHosting/beszel/beszel_data:/beszel_data
      - ${HOME}/Shared/SelfHosting/beszel/beszel_socket:/beszel_socket
    healthcheck:
      test: ['CMD', '/beszel', 'health', '--url', 'http://localhost:8090']
      interval: 120s
      start_period: 10s
      timeout: 5s
  beszel-agent:
    image: henrygd/beszel-agent:latest
    container_name: beszel-agent
    restart: unless-stopped
    network_mode: host
    user: "1000:1000"
    environment:
      - KEY=${BESZEL_AGENT_KEY}
      - LISTEN=/beszel_socket/beszel.sock
      - TOKEN=${BESZEL_AGENT_TOKEN}
      - HUB_URL=https://beszel.thinkcentre.<MY_DOMAIN>
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${HOME}/Shared/SelfHosting/beszel/beszel_socket:/beszel_socket
      - ${HOME}/Shared/SelfHosting/beszel/beszel_agent_data:/var/lib/beszel-agent
    healthcheck:
      test: ['CMD', '/agent', 'health']
      interval: 120s
```

## Hooking up a second agent

I also want an agent running on my backup server. The backup server, a Raspberry
Pi 4 with an external SSD attached via USB, will run the agent as a standalone
container. The hub will reach the backup server using Tailscale. I want to
monitor the external SSD, which I use as a Restic backup target, so
`/mnt/backup` needs to be mounted into the container.

```bash
docker run -d \
    --name beszel-agent \
    --network host \
    --restart unless-stopped \
    -u "1000:1000" \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v ${HOME}/.beszel/beszel_agent_data:/var/lib/beszel-agent \
    -v /mnt/backup/Restic:/extra-filesystems/sdb1__Restic:ro \
    -e KEY="${BESZEL_AGENT_KEY}" \
    -e LISTEN="${BESZEL_AGENT_LISTEN}" \
    -e TOKEN="${BESZEL_AGENT_TOKEN}" \
    -e HUB_URL="https://beszel.thinkcentre.<MY_DOMAIN>" \
    henrygd/beszel-agent:latest
```
