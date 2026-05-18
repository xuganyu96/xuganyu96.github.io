---
layout: page
title: Home lab
---

# Quick start
[`docker-compose.yml`](/homelab/docker-compose.yml)

```bash
# from xuganyu96.github.io/docs
docker compose -f homelab/docker-compose.yml up -d
docker compose -f homelab/docker-compose.yml logs -f
docker compose -f homelab/docker-compose.yml down
```

# Guides
- [Prevent Fedora Desktop w/ GNOME from automatically suspending]({% post_url 2026-05-18-prevent-gnome-auto-suspend %})
- [Backup with restic](#backup-with-restic)
- [Format external SSD](#format-external-ssd-as-bulk-cloud-storage-on-fedora-linux)

# Backup with restic

```bash
# Password can be stored as an environment variable in a file with 600 permission
source ~/.restic.env
restic -r ${RESTIC_REMOTE_URL} backup ${RESTIC_SRC}
restic -r ${RESTIC_REMOTE_URL} forget --keep-last 1 --prune --dry-run
```

# Format external SSD as bulk cloud storage on Fedora Linux
Start with formatting the SSD:

```bash
lsblk -f
sudo umount /dev/sdX
sudo mkfs.btrfs -f -L "external-ssd" /dev/sdX
sudo mkdir -p /mnt/external-ssd
sudo mount /dev/sdX /mnt/external-ssd
sudo chown $(whoami):$(whoami) /mnt/external-ssd
```

From my MacBook, I can use SFTP to connect:

```bash
sftp <user>@<host>:/mnt/external-ssd
```
