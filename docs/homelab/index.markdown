---
layout: page
title: Homelab
---

## Quick start

- [Caddy Status](https://status.thinkcentre.crustaceanlab.com)
- [Audiobookshelf](https://audiobooks.thinkcentre.crustaceanlab.com)
- [Backrest](https://backrest.thinkcentre.crustaceanlab.com)
- [Beszel](https://beszel.thinkcentre.crustaceanlab.com)
- [Copyparty](https://copyparty.thinkcentre.crustaceanlab.com)
- [Dockhand](https://dockhand.thinkcentre.crustaceanlab.com)
- [Immich](https://immich.thinkcentre.crustaceanlab.com)

```bash
# from xuganyu96.github.io/docs
docker compose -f homelab/docker-compose.yml --env-file /path/to/.env up -d
docker compose -f homelab/docker-compose.yml --env-file /path/to/.env logs -f
docker compose -f homelab/docker-compose.yml --env-file /path/to/.env down
```

## Guides

- [Prevent Fedora Desktop w/ GNOME from automatically suspending]({% post_url 2026-05-18-prevent-gnome-auto-suspend %})
- [File sync with `rsync`](#file-sync-with-rsync)
- [Backup with restic](#backup-with-restic)
- [Format external SSD](#format-external-ssd-as-bulk-cloud-storage-on-fedora-linux)

### File sync with `rsync`

A masochist way to manually manage file syncing between remote and local:

```bash
rsync --verbose --info=progress2 -azhru     \
    --exclude ".DS_Store"                   \
    --exclude ".rumdl_cache"                \
    "<src>"                                 \
    "<dst>"                                 \
    --dry-run
```

**Notes:**

- `-azhru` specifies archive mode (`-a`), compression (`-z`), human-readable
  output (`-h`), and skipping files that are newer at destination (`-u`). The
  recursive flag (`-r`) is probably redundant.
- When syncing directories, pay attention to trailing slashes. The source
  directory should have a trailing slash, but the destination directory should
  not have the trailing slash. Otherwise `rysnc` might copy the entire source
  directory into the destination directory instead of individually updating the
  files.

### Backup with restic

```bash
# Password can be stored as an environment variable in a file with 600 permission
source ~/.restic.env
restic -r ${RESTIC_REMOTE_URL} backup ${RESTIC_SRC}
restic -r ${RESTIC_REMOTE_URL} forget --keep-last 1 --prune --dry-run
```

### Format external SSD as bulk cloud storage on Fedora Linux

Start with formatting the SSD:

```bash
lsblk -f
sudo umount /dev/sdX
sudo mkfs.btrfs -f -L "backup" /dev/sdX
sudo mkdir -p /mnt/backup
sudo mount /dev/sdX /mnt/backup
sudo chown $(whoami):$(whoami) /mnt/backup
```

The external SSD will not be mounted on system boot. This can be annoying if the
system suffers from a power loss. We can configure the operating system to
automatically mount the external drive using the file system table `/etc/fstab`.

For the OS to correctly, identify the storage device to mount, we need to find
the external drive's UUID:

```bash
blkid
```

I have previously formatted my external drive with label "my-ssd", so it is easy
to pipe the output of `blkid` into `grep`. We are looking for the field that
reads `UUID="..."` in the output.

A corrupted `/etc/fstab` can brick your OS. With an abundance of caution, I will
edit a copy of the file, validate the config, then overwrite the origin, instead
of editing directly on the original.

```bash
cp /etc/fstab ./fstab.bak
cp /etc/fstab ./fstab.new
echo -e "\n# External drive" >> ./fstab.new
echo "UUID=... /mnt/backup btrfs defaults 0 0" >> ./fstab.new
sudo cp ./fstab.new /etc/fstab
```

After copying over the modified configuration, run `sudo mount -a` to mount all
drives. This command can catch some configuration errors. For example, I made a
typo when copying the UUID, so `mount -a` reports error:

```log
mount: /mnt/backup: can't find UUID=<wrong-uuid>.
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.
```

Reboot the system and check that everthing works:

```bash
sudo reboot
```
