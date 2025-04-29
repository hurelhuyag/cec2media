import 'dart:io';

import 'package:flutter/cupertino.dart';

Future<void> setup({int w = 1920, int h = 1080}) async {
  var p = await Process.start("sudo", ["apt", "install", "-y", "chromium-browser", "chromium-codecs-ffmpeg-extra", "cec-utils", "pulseaudio"]);
  var exitCode = await p.exitCode;
  debugPrint("installing dependencies finished. exitCode: $exitCode");
  p = await Process.start("sudo", ["raspi-config", "nonint", "do_boot_behaviour", "B2"]);
  exitCode = await p.exitCode;
  debugPrint("auto login setup finished. exitCode: $exitCode");
  p = await Process.start("sudo", ["raspi-config", "nonint", "do_audio", "0"]);
  exitCode = await p.exitCode;
  debugPrint("audio output device selected. exitCode: $exitCode");

  await File("/home/pi/.bash_profile").writeAsString("""
if [ -z "\$WAYLAND_DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
  cage /home/pi/media.sh &
fi
  """);
  debugPrint("init script written");

  p = await Process.start("mkdir", ["-p", "/home/pi/.config/mpv"]);
  exitCode = await p.exitCode;
  debugPrint("config dir created. exitCode: $exitCode");

  await File("/home/pi/.config/mpv/mpv.conf").writeAsString("""
vo=gpu
gpu-context=wayland
hwdec=auto-copy
framedrop=decoder
interpolation=no
audio-device=alsa/hdmi:CARD=vc4hdmi0,DEV=0
#audio-channels=5.1
audio-channels=auto
term-status-msg=
#af=lavfi=[channels=5.1]
save-position-on-quit=
hr-seek=yes
#reset-on-seek=yes
#audio-buffer=10000
#cache=yes
#cache-secs=20
autofit=
geometry=${w}x$h
  """);
  debugPrint("mpv config written");

  await File("/home/pi/.config/mpv/input.conf").writeAsString("""
ESC quit
F5 cycle audio
  """);
  debugPrint("mpv input config written");
}