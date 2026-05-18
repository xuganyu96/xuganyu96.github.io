---
layout: post
title:  Prevent Fedora Desktop w/ GNOME from automatically suspending
date:   2026-05-18 00:10:34 -0400
categories: homelab
---

# Diagnostic
Check system journal for what is triggering the suspend:

```bash
journalctl -b
```

# systemd
Create a drop-in systemd configuration that modifies certain automatic suspend settings:
- `HandleLidSwitch` should be set to `ignore`
- `HandleLidSwitchExternalPower` should be set to `ignore`
- `IdleAction` should be set to `ignore`
- `IdleActionSec` should be set to `0`

Then restart systemd-logind

```bash
cp /usr/lib/systemd/logind.conf ~/logind.conf.bak
sed "s/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/" logind.conf.bak \
    | sed "s/#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/" \
    | sed "s/#IdleAction=ignore/IdleAction=ignore/" \
    | sed "s/#IdleActionSec=30min/IdleActionSec=0/" \
    > logind.conf
mkdir -p /etc/systemd/logind.conf.d
sudo cp logind.conf /etc/systemd/logind.conf.d/logind.conf
systemd-analyze cat-config systemd/logind.conf
sudo systemctl restart systemd-logind
```

# GNOME power settings
Check the following GNOME power settings:
- `org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout` should be `0`: never timeout
- `org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type` should be `nothing`: do nothing when timeout happens

```bash
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
```

## GDM power settings
The GNOME display manager (gdm) might also request suspend if the system is idling at the login screen, as such after a reboot, since SSH login does not count.
We need to write a separate config file:

```
[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-timeout=0
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-timeout=0
sleep-inactive-battery-type='nothing'
```

Apply the config:

```bash
sudo cp 01-customize-suspend /etc/dconf/db/gdm.d/01-customize-suspend
sudo dconf update
# verify: this file should exist
ls /etc/dconf/db/gdm
```

# Masking suspend
Not recommended, only use as last resort, especially on laptop.

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```
