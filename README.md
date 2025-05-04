# cec2media

You can build simple home media center using raspberry pi

## Features
- Youtube TV using `chromium` browser
- Plays local video files using `mpv` player
- Displays local photo files using `imv` image viewer
- You can control those programs using your TV's remote through HDMI-CEC.

# Installation

## Operation System

- [Raspberry Pi OS Lite](https://www.raspberrypi.com/software/operating-systems/) /64-bit preferred/
- While preparing sdcard, Enable SSH and Configure WIFI connection

I suppose you know how to prepare Raspberry PI sdcard. You probably needs to connect your Raspberry pi using `ssh` this way configuring is easy

## Our App

- Download deb package from [our release page](https://github.com/hurelhuyag/cec2media/releases). Use `wget` command to download deb package.
- Install it using `sudo apt install ./cec2media-v0.0.8+1-arm64.deb` command
 
```bash
wget https://github.com/hurelhuyag/cec2media/releases/download/v0.0.8%2B1/cec2media-v0.0.8+1-arm64.deb
sudo apt install ./cec2media-v0.0.8+1-arm64.deb
```

###
For better integration you may need to add `hdmi_force_hotplug=1` to `/boot/firmware/config.txt`. Reboot needs to config applies.

Also you may need to update audio output settings using `sudo raspi-config`. Make sure it is defaulted to hdmi0

Also for better performance and sdcard longevity, add those lines to `/etc/fstab` and reboot
```
tmpfs /tmp tmpfs defaults,noatime,nosuid 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid 0 0
tmpfs /var/log tmpfs defaults,noatime,nosuid,size=16m 0 0
```

You need to make sure you connected hdmi cable to your TV's CEC supported port to Raspberry Pi's HDMI0 port.
Tv brands name HDMI-CEC differently, For example Sony Bravia Sync/Link, LG SimpLink, Samsung Anynet+ etc. Myself, I tested with my 13 year old "smart" Sony TV.