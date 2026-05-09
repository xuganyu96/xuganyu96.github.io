---
layout: page
title: Home lab
---

# Backup with restic

```bash
# Password can be stored as an environment variable in a file with 600 permission
source ~/.restic.env
restic -r ${RESTIC_REMOTE_URL} backup ${RESTIC_SRC}
restic -r ${RESTIC_REMOTE_URL} forget --keep-last 1 --prune --dry-run
```

# Prevent suspension on Fedora Desktop
On Fedora 43, a default systemd configuration is located at `/usr/lib/systemd/logind.conf`.
It starts with the following instruction:

> Entries in this file show the compile time defaults. Local configuration
> should be created by either modifying this file (or a copy of it placed in
> /etc/ if the original file is shipped in /usr/), or by creating "drop-ins" in
> the /etc/systemd/logind.conf.d/ directory. The latter is generally
> recommended. Defaults can be restored by simply deleting the main
> configuration file and all drop-ins located in /etc/.

Per recommendation, create a "drop-in", then change the lid settings:

```bash
# for safety, create a draft copy first, then move it only when good to go
cp /usr/lib/systemd/logind.conf ~/logind.conf.bak
sed "s/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/" logind.conf.bak \
    | sed "s/#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/" \
    > logind.conf
mkdir -p /etc/systemd/logind.conf.d
cp logind.conf /etc/systemd/logind.conf.d/logind.conf
```

For a headless desktop (in my case a ThinkCentre tiny), GNOME also tries to suspend the system when idle, which will cause SSH session to be forcefully disconnected. While masking suspend/sleep targets via systemd is a viable solution, it is not elegant and can disrupt legitimate suspends.

```bash
# masking works but is inelegant
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Elegant solution: 
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
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
