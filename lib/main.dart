import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cec2media/launcher_screen.dart';
import 'package:cec2media/libuinput.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nav_path.dart';
import 'mpv_player.dart';

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

late final Process _cecProcess;
final LibUinput _libuinput = LibUinput("libuinput.so");

Future<void> _runCec() async {
  _libuinput.setup();
  /*sendKeyEvent(EV_ABS, 0, 1000);
    sendKeyEvent(EV_ABS, 1, 1000);*/
  _libuinput.sendKeyEvent(EV_REL, 0, 1000); // move cursor away
  _libuinput.sendKeyEvent(EV_REL, 1, 1000); // move cursor away

  debugPrint("uinput setup complete");

  final process = await Process.start("/usr/bin/cec-client", ["-o", "YoutubeTV"]);
  _cecProcess = process;
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
}

Future<void> _runHttpServer() async {
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  debugPrint("http server started");
  await for (var req in server) {
    req.response
      ..statusCode = 200
      ..write("")
      ..close();
    debugPrint("chromium close request received");
    await Process.start("killall", ["chromium"]);
  }
  debugPrint("http server stopped");
}

void main() {
  debugPrint("flutter main");
  runApp(const MyApp());
  ProcessSignal.sigterm.watch().listen((event) {
    debugPrint("sigterm, exiting");
    _libuinput.destroy();
    _cecProcess.kill();
    exit(0);
  },);
  _runHttpServer();
  _runCec();
}

GlobalKey<NavigatorState> _nav = GlobalKey();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      final nav = _nav.currentState;
      if (nav != null && nav.canPop()) {
        nav.pop();
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    super.initState();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MpvPlayerProvider(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          builder: (context, child) {
            return ColoredBox(
              color: Colors.black,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1400),
                  child: child,
                ),
              ),
            );
          },
          navigatorObservers: [AppNavigatorObserver()],
          title: 'Medias',
          scrollBehavior: const MyCustomScrollBehavior(),
          //themeMode: ThemeMode.dark,
          navigatorKey: _nav,
          theme: ThemeData.dark(
            useMaterial3: true,
          ),
          home: const LauncherScreen(),
        ),
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {

  const MyCustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    //PointerDeviceKind.stylus,
    //PointerDeviceKind.invertedStylus,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}