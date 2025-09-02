import 'dart:convert';
import 'dart:io';

import 'package:cec2media/launcher_screen.dart';
import 'package:flutter/material.dart';

class MpvPlayerProvider extends InheritedWidget {

  MpvPlayerProvider({super.key, required super.child, this.useVlc = false});

  final bool useVlc;
  late final MpvPlayer _data = MpvPlayer._(useVlc);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget != this;
  }
}

class MpvPlayer {
  factory MpvPlayer.of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MpvPlayerProvider>()!._data;
  }
  MpvPlayer._(this.useVlc);

  final bool useVlc;

  Process? _process;

  bool get isRunning =>_process != null;

  void play(File file) async {
    if (useVlc) {
      _process = await Process.start(
          "/usr/bin/vlc",
          [
            "--key-leave-fullscreen=F12",
            "--key-quit=Esc",
            "--play-and-exit",
            "--fullscreen",
            "--vout=wayland",
            // "--avcodec-hw=drm",
            "--avcodec-hw=auto",
            "--aout=alsa",
            "--alsa-audio-device=hw:CARD=vc4hdmi0,DEV=0",
            "--stereo-mode=auto",
            file.path
          ]
      );
    } else {
      _process = await Process.start(
          "/usr/bin/mpv",
          [
            "--fs",
            "--geometry=${w}x$h",
            "--config-dir=${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/mpv/",
            file.path
          ]
      );
    }
    _process?.stdout.transform(SystemEncoding().decoder).transform(LineSplitter()).listen((event) => debugPrint("mpv: $event"),);
    _process?.stderr.transform(SystemEncoding().decoder).transform(LineSplitter()).listen((event) => debugPrint("mpv: $event"),);
    _process?.exitCode.then((value) {
      debugPrint("mpv process finished with exit code: $value");
      _process = null;
    },);
  }

  void _writeCmd(List<int> cmd) {
    _process?.stdin.add(cmd);
  }

  void toggleAudios() => _writeCmd([0x23]);
  void toggleSubTitles() => _writeCmd([0x6a]);

  void showMediaInfo() => _writeCmd([0x69]);
  void playPauseToggle() => _writeCmd([0x70]);
  void quit() => _writeCmd([0x71]);

  void seekForward1s() => _writeCmd([0x1b, 0x5b, 0x31, 0x3b, 0x35, 0x43]);
  void seekBackwards1s() => _writeCmd([0x1b, 0x5b, 0x31, 0x3b, 0x35, 0x44]);

  void seekForward5s() => _writeCmd([0x1B, 0x5B, 0x43]);
  void seekBackwards5s() => _writeCmd([0x1B, 0x5B, 0x44]);

  void seekForward5m() => _writeCmd([0x1B, 0x5B, 0x41]);
  void seekBackwards5m() => _writeCmd([0x1B, 0x5B, 0x42]);
}