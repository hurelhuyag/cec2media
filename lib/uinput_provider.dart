/*
import 'dart:convert';
import 'dart:io';

import 'package:cec2media/libuinput.dart';
import 'package:flutter/material.dart';

*/
/*class UinputProvider extends InheritedWidget {
  UinputProvider({super.key, required super.child});

  final Uinput _uinput = Uinput._();

  @override
  bool updateShouldNotify(covariant UinputProvider oldWidget) {
    return _uinput != oldWidget._uinput;
  }
}*//*


class Uinput with ChangeNotifier {
  */
/*factory Uinput.of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UinputProvider>()!._uinput;
  }*//*

  Uinput() {
    _libuinput.setup();
    */
/*sendKeyEvent(EV_ABS, 0, 1000);
    sendKeyEvent(EV_ABS, 1, 1000);*//*

    sendKeyEvent(EV_REL, 0, 1000);
    sendKeyEvent(EV_REL, 1, 1000);

    debugPrint("uinput setup complete");
    _run();
  }
  
  final _libuinput = LibUinput("libuinput.so");
  Process? _process;
  
  Future<void> _run() async {
    try {
      final process = await Process.start("/usr/bin/cec-client", ["-o", "YoutubeTV"]);
      _process = process;
      try {
        debugPrint("listening cec-client");
        final stream = process.stdout.transform(utf8.decoder).transform(LineSplitter());
        await for (var line in stream) {
          debugPrint(line);

          var i = line.indexOf("key released: ");
          var offset = 14;
          bool release = true;
          if (i == -1) {
            i = line.indexOf("key pressed: ");
            offset = 13;
            release = false;
          }
          if (i > 0) {
            i += offset;
            var j = line.indexOf(" ", i);
            var keyName = line.substring(i, j).toLowerCase();
            debugPrint("key: $keyName");

            final key = _keyMap[keyName];
            if (key != null) {
              _libuinput.sendKeyEvent(EV_KEY, key, release ? 0 : 1);
            } else {
              debugPrint("can't find key $keyName");
            }
          }
        }
      } finally {
        debugPrint("\nkilling cec-client process\n");
        process.kill();
      }
    } finally {
      debugPrint("\ncleaning uinput device\n");
      _libuinput.destroy();
    }
  }

  void sendKeyEvent(int type, int code, int value) {
    _libuinput.sendKeyEvent(type, code, value);
  }

  @override
  void dispose() {
    super.dispose();
    debugPrint("Uinput.dispose");
    _process?.kill();
    _libuinput.destroy();
  }
}

final _keyMap = <String, int>{
  "exit": 1, // ESC
  "select": 28, // ENTER
  "setup": 111, // BTN_RIGHT
  "root": 102, // KEY_HOME

  "backward": 165, // prev song
  "forward": 163, // next song

  "play": 164, // PLAY_PAUSE
  "pause": 164, // PLAY_PAUSE
  "stop": 166,
  "rewind": 168,
  "fast": 208, // forward

  "up": 103,
  "left": 105,
  "right": 106,
  "down": 108,

  "f1": 63, // map to f5. Because f1 is help page
  "f2": 60,
  "f3": 61,
  "f4": 62,

  "sub": 36, // subtitle key to v key for mpv subtitle change
};*/
