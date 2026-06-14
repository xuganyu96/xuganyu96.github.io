---
layout: post
title: Setting up Immich
date: 2026-06-13 20:45:00 -0400
---

## Adding Immich containers to my main compose file

```yaml
  immich-server:
    container_name: immich_server
    user: "1000:1000"
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    networks:
      - homelab
    volumes:
      # Do not edit the next line. If you want to change the media storage location on your system, edit the value of UPLOAD_LOCATION in the .env file
      - ${UPLOAD_LOCATION}:/data
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - /home/brucexu/Shared/SelfHosting/.env
    # ports:
    #   - '2283:2283'
    depends_on:
      - redis
      - database
    restart: always
    healthcheck:
      disable: false
  immich-machine-learning:
    container_name: immich_machine_learning
    # NOTE: need to run as root; will report error with user 1000
    networks:
      - homelab
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
    volumes:
      - model-cache:/cache
    env_file:
      - /home/brucexu/Shared/SelfHosting/.env
    restart: always
    healthcheck:
      disable: false
  redis:
    container_name: immich_redis
    user: "1000:1000"
    networks:
      - homelab
    image: docker.io/valkey/valkey:9@sha256:3b55fbaa0cd93cf0d9d961f405e4dfcc70efe325e2d84da207a0a8e6d8fde4f9
    healthcheck:
      test: redis-cli ping || exit 1
    restart: always
  database:
    container_name: immich_postgres
    user: "1000:1000"
    networks:
      - homelab
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23
    env_file:
      - /home/brucexu/Shared/SelfHosting/.env
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
      POSTGRES_INITDB_ARGS: '--data-checksums'
    volumes:
      # Do not edit the next line. If you want to change the database storage location on your system, edit the value of DB_DATA_LOCATION in the .env file
      - ${DB_DATA_LOCATION}:/var/lib/postgresql/data
    shm_size: 128mb
    restart: always
    healthcheck:
      disable: false

volumes:
  model-cache:
```

## Reverse proxy

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

*.thinkcentre.crustaceanlab.com {
    import cloudflare
}

status.thinkcentre.crustaceanlab.com {
    respond "Ok"
    import cloudflare
}

audiobooks.thinkcentre.crustaceanlab.com {
    reverse_proxy audiobookshelf:80
    import cloudflare
}

backrest.thinkcentre.crustaceanlab.com {
    reverse_proxy backrest:9898
    import cloudflare
}

immich.thinkcentre.crustaceanlab.com {
    reverse_proxy immich_server:2283
    import cloudflare
}
```

## References

- [Install Immich with Docker Compose](https://docs.immich.app/install/docker-compose/)