---
layout: post
title: Cloudflare TLS Certificates
date: 2026-06-07
---

This is part 3 of my homelab journey. For previous part check
[this post]
({% post_url /homelab/2026-05-31-certificates-reverse-proxy-audiobookshelf %})

In the previous part, I set up TLS certificate using `tailscale cert` and a
Caddy reverse proxy. This setup works well enough on its own, but soon I ran
into problems trying to serve various services under subpaths such as
`/backrest` since many services are not built to be hosted under a subpath, but
rather a subdomain like `backrest.thinkcentre.taileeXXXX.ts.net`. Among these
services not supporting subpath is Immich, which I consider to be an essential
service, hence the need to re-visit the problem of TLS certificates.

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

## Reference

- [Remotely access and share your self-hosted services](https://youtu.be/Vt4PDUXB_fg?si=cvYagD2GlTw2OcSI&t=214)
- [Using Caddy with Cloudflare](https://samjmck.com/en/blog/using-caddy-with-cloudflare/#2-using-a-lets-encrypt-certificate)
- [Docker Compose how-to's: environment variables](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/#env-file)
