---
layout: post
title: "Certificates, reverse proxy, and Audiobookshelf"
date: 2026-05-31 15:45:00 -0400
---

<!--
This is index 1 of the homelab series. Check
[index 0] for hardware and
operating system setup.
-->

## Generate certificates

I want to set up Caddy with SSL certificates, so we will generate the
certificates first. Tailscale can generate SSL certificate and private keys,
although this feature is disabled by default and needs to be explicitly enabled
([reference](https://tailscale.com/docs/how-to/set-up-https-certificates#configure-https)).

SSL certificate and private key management is a rabbit hole that I can make an
entire career out of. For now, since everything will only be served on my
private tailnet with me being the only user, I will keep things to a minimum,
which means storing certificate and private key files on the file system with
appropriate permissions, but leave them out of the backups.

```bash
mkdir ~/.ssl
sudo tailscale cert \
  --cert-file ~/.ssl/thinkcentre.cert \
  --key-file ~/.ssl/thinkcentre.key \
  thinkcentre.taileeXXXX.ts.net
```

With the commands above, the `~/.ssl` directory is owned by the non-privileged
user, while the certificate and private key are owned by root. We need to change
file ownership for the certificate and private key, then configure the
permissions appropriately:

```bash
sudo chown -R admin:admin ~/.ssl
sudo chmod 0700 .ssl
sudo chmod 0400 .ssl/thinkcentre.cert
sudo chmod 0400 .ssl/thinkcentre.key
```

Check that the permissions are correct:

```bash
drwx------. 1 admin admin    62 May 30 16:04 .ssl
-r--------. 1 admin admin  4853 May 30 16:04 thinkcentre.cert
-r--------. 1 admin admin   227 May 30 16:04 thinkcentre.key
```

From here we can inspect the certificate and the key using OpenSSL.

```bash
openssl x509 -in .ssl/thinkcentre.cert -text -noout
openssl ec -in .ssl/thinkcentre.key -text -noout
```

What's important is that Tailscale generated a certificate chain that traces up
to Let's Encrypt as the root CA, which will hopefully prevent browsers from
raising the spooky alerts about self-signed certificates.

## Setting up Caddy

### Test run

[Caddy's DockerHub page](https://hub.docker.com/_/caddy) shows a minimal example
that starts a container running Caddy:

```bash
echo "Hello, world" > index.html
docker run -d -p 80:80 \
  -v $PWD/index.html:/usr/share/caddy/index.html \
  -v caddy_data:/data \
  caddy:2.11.3-alpine
```

Go to a client browser and connect to `http://thinkcentre.taileeXXXX.ts.net`,
the page should show "Hello, world". Alternative, `curl` with the `-v` flag is
a helpful tool for troubleshooting.

```bash
# This returns the index
curl -v http://thinkcentre.taileeXXXX.ts.net
# This tails to connect, which makes sense because we don't have certificate yet
curl -v https://thinkcentre.taileeXXXX.ts.net
```

Next, we'll move the `docker run` command into the `docker-compose.yml` file:

```yaml
services:
  caddy:
    image: caddy:2.11.3-alpine
    ports:
      - 80:80
    volumes:
      - /path/to/index.html:/usr/share/caddy/index.html
```

This validates that a Caddy container can indeed serve content on port 80, but
for non-trivial features such as TLS and reverse proxy, setting up a Caddyfile
is the more appropriate way to run Caddy. Again, I will begin with a simple
configuration that can serve as a health check:

```caddy
http://thinkcentre.taileeXXXX.ts.net/health {
    respond "Ok"
}
```

In my setup, this Caddyfile is written to a directory dedicated to Caddy
configuration files. This `caddy/conf` directory is then bind-mounted into the
Caddy container at `/etc/caddy` ([reference](https://hub.docker.com/_/caddy#%EF%B8%8F-do-not-mount-the-caddyfile-directly-at-etccaddycaddyfile)).
The compose file should look like this now:

```yaml
services:
  caddy:
    image: caddy:2.11.3-alpine
    ports:
      - 80:80
    volumes:
      - /home/brucexu/Shared/SelfHosting/caddy/conf:/etc/caddy
```

From client machine:

```bash
curl http://thinkcentre.taileeXXXX.ts.net/health
```

### Add TLS certificate

Recall from earlier that my TLS certificate (`thinkcentre.cert`) and my private
key (`thinkcentre.key`) are both stored under `~/.ssl`. I can now mount this
entire directory into the Caddy container using bind mount. I will also open
port 443 on the Caddy container for HTTPS.

```yaml
services:
  caddy:
    image: caddy:2.11.3-alpine
    ports:
      - 80:80
      - 443:443
    volumes:
      - /home/brucexu/Shared/SelfHosting/caddy/conf:/etc/caddy
      - /home/brucexu/.ssl:/ssl:ro
```

Then I will modify the Caddyfile so that `thinkcentre.taileeXXXX.ts.net/health`
can be served over HTTPS. Notice that the `http://` header is removed, so Caddy
will automatically serve HTTPS. Also notice that the certificate and key are
specified using the bind mount path.

```caddy
thinkcentre.taileeXXXX.ts.net/health {
    respond "Ok"
    tls /ssl/thinkcentre.cert /ssl/thinkcentre.key
}
```

The client can validate the HTTPS setup with:

```bash
curl https://thinkcentre.taileeXXXX.ts.net/health
```

For some finishing touch, I will bind mount the data directory into the Caddy
container at `/data`, configure `docker-compose.yml` file so that Caddy
automatically restarts (e.g. after power loss). Finally, I will set the Caddy
container to run as a non-privileged user, otherwise Caddy will wrote to mounted
volumes as `root`, which makes it annoying when trying to back up data using
`restic` as non-privileged user. One way to do it is by using the non-privileged
user running Docker Compose, whose user ID can be found with the `id` command.

```yaml
services:
  caddy:
    image: caddy:2.11.3-alpine
    user: "1000:1000"
    ports:
      - 80:80
      - 443:443
    volumes:
      - /home/brucexu/Shared/SelfHosting/caddy/conf:/etc/caddy
      - /home/brucexu/Shared/SelfHosting/caddy/data:/data
      - /home/brucexu/.ssl:/ssl:ro
```

### Hooking up Audiobookshelf

My first user-facing service is [Audiobookshelf](https://www.audiobookshelf.org).

```yaml
services:
  audiobookshelf:
    image: ghcr.io/advplyr/audiobookshelf:latest
    user: "1000:1000"
    ports: 13378:80
    restart: unless-stopped
    volumes:
      - /home/brucexu/Shared/SelfHosting/audiobookshelf/audiobooks:/audiobooks
      - /home/brucexu/Shared/SelfHosting/audiobookshelf/podcasts:/podcasts
      - /home/brucexu/Shared/SelfHosting/audiobookshelf/config:/config
      - /home/brucexu/Shared/SelfHosting/audiobookshelf/metadata:/metadata
    environment:
      - TZ=America/Toronto
```

With this setup alone, I can access Audiobookshelf using
`http://thinkcentre.taileeXXXX.ts.net:13378` to validate that the service itself
is working. Then, I will hook up Caddy as a reverse proxy in front of
Audiobookshelf. Thanks to Docker's networking features, Caddy can connect to the
Audiobookshelf container using the service name. First, I will edit the
Caddyfile to so that Caddy will route requests for
`thinkcentre.taileeXXXX.ts.net/audiobookshelf` to the Audiobookshelf container.
Second, since both the health check and the Audiobookshelf service use the same
set of TLS credentials, it can be abstracted into a shared directive. The
modified Caddy file should look like this:

```caddy
(tailscalecert) {
    tls /ssl/thinkcentre.cert /ssl/thinkcentre.key
}

thinkcentre.taileeXXXX.ts.net/health {
    respond "Ok"
    import tailscalecert
}

thinkcentre.taileeXXXX.ts.net/audiobookshelf* {
    reverse_proxy audiobookshelf:80
    import tailscalecert
}
```

Last but not least, I will edit the `docker-compose.yml` file so that the Caddy
container and the Audiobookshelf container are connected on the same network.
Here is the [final state](https://github.com/xuganyu96/xuganyu96.github.io/blob/c49680d4c22fc4d65bd34db511b3fa07b53e5ada/docs/homelab/docker-compose.yml)
of my `docker-compose.yml` at the end of this post:

```yaml
name: homelab

services:
  caddy:
    image: caddy:2.11.3-alpine
    user: "1000:1000"
    restart: unless-stopped
    ports:
      - 80:80
      - 443:443
    volumes:
      - /home/brucexu/Shared/SelfHosting/caddy/conf:/etc/caddy
      - /home/brucexu/Shared/SelfHosting/caddy/data:/data
      - /home/brucexu/.ssl:/ssl:ro
    networks:
      - homelab
  audiobookshelf:
    image: ghcr.io/advplyr/audiobookshelf:latest
    user: "1000:1000"
    restart: unless-stopped
    volumes:
      - /home/brucexu/Shared/SelfHosting/audiobookshelf/audiobooks:/audiobooks
      - /home/brucexu/Shared/SelfHosting/audiobookshelf/podcasts:/podcasts
      - /home/brucexu/Shared/SelfHosting/audiobookshelf/config:/config
      - /home/brucexu/Shared/SelfHosting/audiobookshelf/metadata:/metadata
    environment:
      - TZ=America/Toronto
    networks:
      - homelab

networks:
  homelab:
```
