# cec2media

A new Flutter project.

# Config

## OS config

```bash
sudo apt install -y vim weston chromium-browser chromium-codecs-ffmpeg-extra cec-utils pulseaudio
sudo raspi-config nonint do_boot_behaviour B2
sudo raspi-config nonint do_audio 0
```

## /boot/firmware/config.txt
```txt
hdmi_force_hotplug=1
```

## ~/.config/weston.ini
```ini
[core]
idle-time=0
#shell=kiosk-shell.so
shell=desktop-shell.so

[desktop-shell]
panel-position=top

[shell]
cursor-theme=default
locking=false

[launcher]
icon=/usr/share/icons/Adwaita/24x24/legacy/utilities-terminal.png
path=/usr/bin/weston-terminal

[launcher]
icon=/usr/share/icons/hicolor/24x24/apps/chromium.png
path=/home/pi/start.sh

[launcher]
icon=/usr/share/icons/Adwaita/24x24/legacy/multimedia-player.png
path=/home/pi/media.sh

[autolaunch]
#path=/home/pi/start.sh
path=/usr/bin/weston-terminal

[keyboard]
key=F2
command=/home/pi/start.sh

[keyboard]
key=F3
command=/home/pi/media.sh
```


## ~/.config/mpv/mpv.conf
```conf
vo=gpu
gpu-context=wayland
hwdec=auto-copy
framedrop=decoder
interpolation=no
audio-device=alsa/hdmi:CARD=vc4hdmi0,DEV=0
#audio-channels=5.1
audio-channels=auto
term-status-msg=
save-position-on-quit=
```

### ~/.config/mpv/input.conf
```
ESC quit
F5 cycle audio
```

### /home/pi/media.sh
```bash
#!/bin/bash
killall chromium-browser
killall mpv

GTK_USE_PORTAL=0 /home/pi/cec2media/build/linux/arm64/release/bundle/cec2media > /tmp/media.log 2>&1
```
### /home/pi/start.sh
```bash
#!/bin/bash
APP="https://www.youtube.com/tv"
GEO="$(fbset -s | awk '$1 == "geometry" { print $2":"$3 }')"
WIDTH=$(echo "$GEO" | cut -d: -f1)
HEIGHT=$(echo "$GEO" | cut -d: -f2)

echo "Resolution: $WIDTH x $HEIGHT"

killall mpv
killall cec2media

/usr/bin/chromium-browser --kiosk --start-fullscreen --start-maximized --window-position=0,0 --window-size=$WIDTH,$HEIGHT \
	  --ozone-platform=wayland \
	  --enable-features=UseOzonePlatform \
      --enable-features=VaapiVideoDecoder \
	  --enable-zero-copy \
	  --enable-gpu-rasterization \
	  --user-data-dir="youtubetv" \
	  --user-agent="Mozilla/5.0 (PS4; Leanback Shell) Gecko/20100101 Firefox/65.0 LeanbackShell/01.00.01.75 Sony PS4/ (PS4, , no, CH)" \
	  --force-dark-mode --enable-features=WebUIDarkMode \
	  --no-default-browser-check --disable-translate --fast --fast-start --disable-features=TranslateUI --password-store=basic --no-first-run \
	  --app $APP
```

## ~/.bash_profile
```bash
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  export XDG_CURRENT_DESKTOP=weston
  weston &

  sleep 2

  systemctl --user restart xdg-desktop-portal-wlr.service
fi
```

## Speaker Test
```bash
speaker-test -c6 -D hdmi:CARD=vc4hdmi0,DEV=0 --audio-channels=5.1
```