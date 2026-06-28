---
layout: post
title: Late June 2026 home server updates
date: 2026-06-28 11:50:00 -0400
---

Added Immich and copyparty, though copyparty is probably not correctly
configured

## Adding a backup target

I have a Raspberry Pi 4B with 4GB of RAM lying aroun collecting dust and would
like to repurpose it as a backup target. I plan to attach an external SSD via
one of the USB 3 ports.

First, I need to remove that external SSD from my existing home server. First
remove the corresponding backup target from Backrest. Then remove the
corresponding entry from fstab so the operating system does not try to mount
this external SSD on startup.

```bash
cp /etc/fstab ~/fstab
cp ~/fstab ~/fstab.bak
# edit ~/fstab and remove the appropriate entry
sudo cp ~/fstab /etc/fstab
# validate by mounting everything
sudo mount -a
sudo reboot
```

Note the entry we removed:

```text
# External drive
UUID=<REDACTED> /mnt/backup btrfs defaults 0 0
```

After reboot, check that the external SSD is not automatically mounted with
`lsblk`. I also checked that my existing services get back up successfully. We
are done with the main home server.

Now onto the Raspberry Pi. Connect the external SSD to the Pi and inspect with
`lsblk`. I've mounted this external SSD before, and it seemed like Raspberry Pi
OS automatically mounted it when attached, so I needed to unmount it with
`sudo umount /dev/<sdX>`, then mount it back to the desired location with
`sudo mount /dev/<sdX> /mnt/backup`. After the mount succeeds, I can inspect
the content:

```bash
restic -r /mnt/backup/Restic check
```

Now we will add the deleted `fstab` entry back. Use `lsblk -f` to show the UUID
of the device, which should be the same as what was removed earlier.
