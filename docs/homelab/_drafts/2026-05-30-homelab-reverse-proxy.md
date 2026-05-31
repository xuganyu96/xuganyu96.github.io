---
layout:     post
title:      "Home lab: reverse proxy"
date:       2026-05-30 15:40:26 -0400
---

<!-- TODO: scrub all mentions of `brucexu` -->

# Generate certificates

Everything is connected in a private network using Tailscale.

I want to set up Caddy with SSL certificates, so we will generate the
certificates first. Tailscale can generate SSL certificate and private keys,
although this feature is disabled by default and needs to be explicitly enabled
([reference](https://tailscale.com/docs/how-to/set-up-https-certificates#configure-https)).

Generate the certicate with the `tailscale cert` command:

```text
Get TLS certs

USAGE
  tailscale cert [flags] <domain>

FLAGS
  --cert-file value
        output cert file or "-" for stdout; defaults to DOMAIN.crt if --cert-file and --key-file are both unset
  --key-file value
        output key file or "-" for stdout; defaults to DOMAIN.key if --cert-file and --key-file are both unset
  --min-validity value
        ensure the certificate is valid for at least this duration; the output certificate is never expired if this flag is unset or 0, but the lifetime may vary; the maximum allowed min-validity depends on the CA (default 0s)
  --serve-demo, --serve-demo=false
        if true, serve on port :443 using the cert as a demo, instead of writing out the files to disk (default false)
```

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

# Test running Caddy

```bash
echo "hello world" > index.html
docker run -d -p 80:80 \
  -v $PWD/index.html:/usr/share/caddy/index.html \
  -v caddy_data:/data \
  caddy
```

```yaml
services:
  caddy:
    image: caddy:2.11.3-alpine
    ports:
      - 80:80
    volumes:
      - /path/to/index.html:/usr/share/caddy/index.html
```

```bash
# This returns the index
curl http://thinkcentre.taileeXXXX.ts.net
# This tails to connect, which makes sense because we don't have certificate yet
curl https://thinkcentre.taileeXXXX.ts.net
```

Start with a Caddyfile that can serve something over HTTP.

```caddy
http://thinkcentre.taileeXXXX.ts.net/health {
    respond "Ok"
}
```

From client machine:

```bash
curl http://thinkcentre.taileeXXXX.ts.net/health
```

We can now add TLS certificates:

```caddy
thinkcentre.taileeXXXX.ts.net/health {
    respond "Ok"
    tls /ssl/thinkcentre.cert /ssl/thinkcentre.key
}
```

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

Need to run Caddy as non-privileged user, or Caddy will write to mounted volumes
as `root`, which makes it annoying when trying to back up data using `restic`
as non-privileged user. One way to do it is by using the non-privileged user
running Docker Compose, whose user ID can be obtained with the `id` command.

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

# Hooking up audiobookshelf

```yaml
name: homelab

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