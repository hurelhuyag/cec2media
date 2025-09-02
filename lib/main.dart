import 'dart:io';
import 'dart:ui';

import 'package:cec2media/graceful_shutdown.dart';
import 'package:cec2media/launcher_screen.dart';
import 'package:cec2media/uinput_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nav_path.dart';
import 'mpv_player.dart';

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

void main(List<String> args) {
  final useVlc = args.contains("--useVlc");
  debugPrint("flutter main");
  runApp(
    GracefulShutdown(
      child: MyApp(useVlc: useVlc,)
    )
  );
  _runHttpServer();
}

GlobalKey<NavigatorState> _nav = GlobalKey();

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.useVlc});

  final bool useVlc;

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
      useVlc: widget.useVlc,
      child: UInputProvider(
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