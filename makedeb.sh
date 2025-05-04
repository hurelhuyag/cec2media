#!/bin/bash

set -e

ARCH=$(dpkg --print-architecture)
ARCH_F=$(uname -m)

if [[ "$ARCH_F" == "aarch64" ]];
then
  ARCH_F="arm64"
elif [[ "$ARCH_F" == "x86_64" ]];
then
  ARCH_F="x64"
fi

APP_NAME=$(cat pubspec.yaml | grep name: | cut -d ' ' -f2)
VERSION=$(cat pubspec.yaml | grep version: | cut -d ' ' -f2)
SOURCE="build/linux/$ARCH_F/release/bundle";
TARGET="build/linux/$ARCH_F/release/$APP_NAME-$VERSION";

flutter build linux --release --obfuscate --split-debug-info="build/linux/$ARCH_F/release/symbols"
mkdir -p "$TARGET/DEBIAN/"
mkdir -p "$TARGET/usr/bin/"
mkdir -p "$TARGET/usr/lib/"
mkdir -p "$TARGET/opt/$APP_NAME/"
mkdir -p "$TARGET/etc/systemd/system"
mkdir -p "$TARGET/etc/udev/rules.d/"

CONTROL=$(cat <<-END
Package: $APP_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: hurelhuyag <hurelhuyag@gmail.com>
Depends: cage, chromium-browser, chromium-codecs-ffmpeg-extra, cec-utils, pulseaudio, imv, mpv, libuinput-dev
Installed-Size: 22600
Homepage: https://www.github.com/hurelhuyag/$APP_NAME
Description: This is designed to watch Youtube TV, or your local video contents on your tv controlled by TV remotes vis HDMI-CEC

END
)

SERVICE=$(cat <<-END
[Unit]
Description=Youtube TV on %I
# Make sure we are started after logins are permitted. If Plymouth is
# used, we want to start when it is on its way out.
After=systemd-user-sessions.service plymouth-quit-wait.service
# Since we are part of the graphical session, make sure we are started
# before it is complete.
Before=graphical.target
# On systems without virtual consoles, do not start.
ConditionPathExists=/dev/tty0
# D-Bus is necessary for contacting logind, which is required.
Wants=dbus.socket systemd-logind.service
After=dbus.socket systemd-logind.service
# Replace any (a)getty that may have spawned, since we log in
# automatically.
Conflicts=getty@%i.service
After=getty@%i.service

[Service]
Type=simple
ExecStart=/usr/bin/cage /opt/$APP_NAME/$APP_NAME
ExecStartPost=+sh -c "tty_name='%i'; exec chvt $${tty_name#tty}"
Restart=always
User=pi
# Log this user with utmp, letting it show up with commands 'w' and
# 'who'. This is needed since we replace (a)getty.
UtmpIdentifier=%I
UtmpMode=user
# A virtual terminal is needed.
TTYPath=/dev/%I
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
# Fail to start if not controlling the virtual terminal.
StandardInput=tty-fail

# Set up a full (custom) user session for the user, required by Cage.
PAMName=pi

[Install]
WantedBy=graphical.target
Alias=display-manager.service
DefaultInstance=tty7

END
)

POST_INSTALL=$(cat <<-END
#!/bin/sh

ln -s /etc/systemd/system/cec2media@.service /etc/systemd/system/graphical.target.wants/$APP_NAME@tty1.service
systemctl set-default graphical.target
systemctl daemon-reload

# uinput config
echo "uinput" | tee -a /etc/modules
modprobe uinput
udevadm control --reload-rules
udevadm trigger
usermod -aG input pi
ldconfig

END
)

PRE_RM=$(cat <<-END
#!/bin/sh

systemctl stop $APP_NAME@tty1.service
unlink /etc/systemd/system/graphical.target.wants/$APP_NAME@tty1.service
systemctl daemon-reload

END
)

POST_RM=$(cat <<-END
# uinput config cleanup
ldconfig
gpasswd -d pi input
udevadm control --reload-rules
udevadm trigger
sed -i '/^uinput$/d' /etc/modules
sudo modprobe -r uinput

END
)

UDEV_RULES=$(cat <<-END
KERNEL=="uinput", MODE="0660", GROUP="input"

END
)

echo "$CONTROL" | tee "$TARGET/DEBIAN/control"
echo "$POST_INSTALL" | tee "$TARGET/DEBIAN/postinst"
echo "$PRE_RM" | tee "$TARGET/DEBIAN/prerm"
echo "$POST_RM" | tee "$TARGET/DEBIAN/postrm"
echo "$SERVICE" | tee "$TARGET/etc/systemd/system/$APP_NAME@.service"
echo "$UDEV_RULES" | tee "$TARGET/etc/udev/rules.d/90-uinput.rules"
cp -pr "$SOURCE"/* "$TARGET/opt/$APP_NAME"
cp libuinput.so "$TARGET/usr/lib/"
ln -sf "/opt/$APP_NAME/$APP_NAME" "$TARGET/usr/bin/$APP_NAME"
chmod +x "$TARGET/DEBIAN/postinst"
chmod +x "$TARGET/DEBIAN/prerm"
chmod +x "$TARGET/DEBIAN/postrm"
dpkg -b "$TARGET"