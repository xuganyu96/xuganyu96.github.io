---
layout: post
title: Use Caddy with Cloudflare
date: 2026-06-07
---

In the [previous part]({% post_url
/homelab/2026-05-31-certificates-reverse-proxy-audiobookshelf %}),
I set up TLS certificate using `tailscale cert` and a Caddy reverse proxy. This
setup works well enough on its own, but soon I ran into problems trying to serve
various services under subpaths such as `/backrest` since many services are not
built to be hosted under a subpath, but rather a subdomain like
`backrest.thinkcentre.taileeXXXX.ts.net`. Among these services not supporting
subpath is Immich, which I consider to be an essential service, hence the need
to re-visit the problem of TLS certificates.

Unfortunately, Tailscale does support generating certificates for other domains
than the fully-qualified domain of the Tailscale node itself (e.g. I cannot
use Tailscale to generate certificates for `*.thinkcentre.taileeXXXX.ts.net`).
After some initial research, I concluded that my best course of action is to
use Cloudflare, with whom I already purchased a domain name. The idea is to
configure DNS records on Cloudflare so that my domain name resolves to the
private IP address within my Tailscale network, then configure Caddy on my
homelab to obtain TLS credentials from Cloudflare.

## Configure DNS record on Cloudflare

I want a collection of subdomain names to resolve to the private domain name or
private IP address on my Tailscale network. Go to Cloudflare's dashboard, go to
"Domains", click the desired domain name, click "DNS Records", then click
"Add record". I will add a CNAME record that says `*.thinkcentre.mydomain.com`
is an alias for `thinkcentre.taileeXXXX.ts.net`. After saving the record, I can
use `dig foo.thinkcentre.mydomain.com` to verify:

```bash
dig foo.thinkcentre.mydomain.com
```

My output is:

```log
; <<>> DiG 9.10.6 <<>> foo.thinkcentre.mydomain.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 55842
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1220
;; QUESTION SECTION:
;foo.thinkcentre.mydomain.com. IN  A

;; ANSWER SECTION:
foo.thinkcentre.mydomain.com. 300 IN CNAME thinkcentre.taileeXXXX.ts.net.

;; AUTHORITY SECTION:
[REDACTED]

;; Query time: 41 msec
;; SERVER: 100.100.100.100#53(100.100.100.100)
;; WHEN: Sun Jun 07 00:26:39 EDT 2026
;; MSG SIZE  rcvd: 169
```

The answer section indicates the correct result.

Since we are on Cloudflare, we can also create an API key that we will later use
with Caddy so Caddy can automatically obtain TLS certificates from Cloudflare
using DNS challenge. I will store the API key in an `.env` file that is sourced
by `docker compose` using the `--env-file` flag, then the API key will be passed
to the Caddy container as an environment variable `CADDY_CLOUDFLARE_TOKEN`.

```bash
# The project-level .env file for docker compose
CADDY_CLOUDFLARE_TOKEN="..."
```

```yaml
# Pass the environment variable to Caddy
services:
  caddy:
    environment:
      - CADDY_CLOUDFLARE_TOKEN=${CADDY_CLOUDFLARE_TOKEN}
```

```bash
# Start docker compose with specified environment file
docker compose --env-file ~/Shared/SelfHosting/.env up
```

The Caddyfile can reference environment variable with
`{env.CADDY_CLOUDFLARE_TOKEN}`. For validation, I defined a directive that serves
the token under some subpath. After restarting Caddy, the API token should be
visible from that subpath.

```caddyfile
thinkcentre.tailee7580.ts.net/cf {
    respond {env.CADDY_CLOUDFLARE_TOKEN}
    import tailscalecert
}
```

## Build Caddy with the Cloudflare Module

To use ACME DNS challenge with Cloudflare, we will use the following snippet.
Note that `resolvers 1.1.1.1` is necessary in my Tailscale networking setup.

```caddyfile
(cloudflare) {
    tls {
        dns cloudflare {env.CADDY_CLOUDFLARE_TOKEN}
        resolvers 1.1.1.1
    }
}
```

For each reverse proxy section, import the cloudflare section. However, the
vanilla Caddy image does not include the plugin for interfacing with Cloudflare,
and the Caddy container will exit upon reading an unsupported module:

> Error: adapting config using caddyfile: parsing caddyfile tokens for 'tls':
> getting module named 'dns.providers.cloudflare': module not registered:
> dns.providers.cloudflare, at /etc/caddy/Caddyfile:7 import chain
> ['/etc/caddy/Caddyfile:13 (import cloudflare)']

We need to extend the base Docker image to include the appropriate plugin. This
can be done by using a custom Dockerfile that builds the `caddy` binary with the
desired plugin:

```dockerfile
FROM caddy:2.11.3-builder-alpine AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM caddy:2.11.3-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```

We can validate that this Dockerfile builds correctly with:

```bash
docker build -t caddy:dev -f caddy.Dockerfile .
```

On my home server this takes roughly one minute to complete. Finally, We will
modify the `docker-compose.yaml` file so that Docker Compose will use the image
built from my Dockerfile instead of a pre-built image from DockerHub.

```yaml
services:
  caddy:
    build:
      context: .
      dockerfile: caddy.Dockerfile
```

After `docker compose --env-file <path> up`, the Caddy container no longer
crashes. We can validate the existing routes that uses Tailscale certificates.

Now we can add our first route that uses the Cloudflare DNS challenge for
certificates:

```caddyfile
status.thinkcentre.crustaceanlab.com {
    respond "Ok"
    import cloudflare
}
```

Restart the containers and observe that Caddy will take a few seconds to solve
the DNS challenge:

```log
{"msg":"trying to solve challenge",,"challenge_type":"dns-01","ca":"REDACT"}
{"msg":"authorization finalized","identifier":"REDACTED","authz_status":"valid"}
{"msg":"validations succeeded; finalizing order","order":"REDACTED"}
{"msg":"got renewal info","names":["REDACTED"]}
{"msg":"got renewal info","names":["REDACTED"]}
{"msg":"got renewal info","names":["REDACTED"]}
{"msg":"successfully downloaded available certificate chains"}
{"msg":"certificate obtained successfully","issuer":"REDACTED"}
{"msg":"releasing lock","identifier":"REDACTED"}
```

Now navigate to [https://status.thinkcentre.crustaceanlab.com] and inspect the
certificate, which should have "subject name" set to
`status.thinkcentre.crustaceanlab.com`. Finally, we can clean up the Caddyfile
and servce all services under subdomains instead of subpaths:

```caddyfile
(tailscalecert) {
    tls /ssl/thinkcentre.cert /ssl/thinkcentre.key
}

(cloudflare) {
    tls {
        dns cloudflare {env.CADDY_CLOUDFLARE_TOKEN}
        resolvers 1.1.1.1
    }
}

thinkcentre.tailee7580.ts.net {
    handle_path /health {
        respond "Ok"
    }
    import tailscalecert
}

status.thinkcentre.crustaceanlab.com {
    respond "Ok"
    import cloudflare
}

audiobooks.thinkcentre.crustaceanlab.com {
    reverse_proxy audiobookshelf:80
    import cloudflare
}
```

## Reference

- [Remotely access and share your self-hosted services](https://youtu.be/Vt4PDUXB_fg?si=cvYagD2GlTw2OcSI&t=214)
- [Using Caddy with Cloudflare](https://samjmck.com/en/blog/using-caddy-with-cloudflare/#2-using-a-lets-encrypt-certificate)
- [Docker Compose how-to's: environment variables](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/#env-file)
- [caddy - Official image: Adding custom Caddy modules](https://hub.docker.com/_/caddy#adding-custom-caddy-modules)
