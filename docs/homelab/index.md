---
layout: page
title: Home Lab Setup
---

# Using external SSD as bulk cloud storage on Fedora Linux
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