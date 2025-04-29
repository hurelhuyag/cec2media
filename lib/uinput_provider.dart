import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cec2media/libuinput.dart';
import 'package:flutter/material.dart';

class UInputProvider extends StatefulWidget {
  const UInputProvider({super.key, required this.child});

  final Widget child;

  @override
  State<UInputProvider> createState() => _UInputProviderState();
}

class _UInputProviderState extends State<UInputProvider> {

  final UInput _uInput = UInput._();
  
  @override
  void dispose() {
    _uInput.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return _UInputInheritedWidget(
      _uInput,
      child: widget.child
    );
  }
}

class _UInputInheritedWidget extends InheritedWidget {
  const _UInputInheritedWidget(this._uInput, {required super.child});

  final UInput _uInput;

  @override
  bool updateShouldNotify(covariant _UInputInheritedWidget oldWidget) {
    return _uInput != oldWidget._uInput;
  }
}


class UInput with ChangeNotifier {
  factory UInput.of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_UInputInheritedWidget>()!._uInput;
  }

  final _libuinput = LibUinput("libuinput.so");
  Process? _cecProcess;
  StreamSubscription<String>? _cecSub;

  UInput._() {
    _libuinput.setup();
    /*sendKeyEvent(EV_ABS, 0, 1000);
    sendKeyEvent(EV_ABS, 1, 1000);*/
    sendKeyEvent(EV_REL, 0, 1000); // move cursor away
    sendKeyEvent(EV_REL, 1, 1000); // move cursor away
    debugPrint("uinput setup complete");
    _startCecProcess();
    //_initSignalHandlers();
  }

  Future<void> _startCecProcess() async {
    final process = await Process.start("/usr/bin/cec-client", ["-o", "YoutubeTV"]);
    _cecProcess = process;
    debugPrint("cec-client process started");
    _cecSub = process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen(_handleCecLine);
    debugPrint("cec-client process listened");
  }

  void _handleCecLine(String line) {
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

  void sendKeyEvent(int type, int code, int value) {
    _libuinput.sendKeyEvent(type, code, value);
  }
  
  void sendCecEvent(String event) {
    _cecProcess?.stdin.writeln(event);
    _cecProcess?.stdin.flush();
  }

  @override
  void dispose() {
    super.dispose();
    debugPrint("UInput.dispose");
    debugPrint("\nkilling cec-client process\n");
    _cecSub?.cancel();
    _cecProcess?.kill();
    debugPrint("\ncleaning uinput device\n");
    _libuinput.destroy();
    debugPrint("Uinput,CEC are cleaned up");
  }

  /*void _initSignalHandlers() {
    List<StreamSubscription<ProcessSignal>> signalSubs = [];
    void handleProcessSignal(ProcessSignal signal) {
      for (var sub in signalSubs) {
        sub.cancel();
      }
      dispose();
    }
    signalSubs.add(ProcessSignal.sigterm.watch().listen(handleProcessSignal));
    signalSubs.add(ProcessSignal.sigint.watch().listen(handleProcessSignal));
  }*/
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
};
