import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'nav_path.dart';
import 'mpv_player.dart';

void main() {
  debugPrint("flutter main");
  runApp(const MyApp());
  ProcessSignal.sigterm.watch().listen((event) {
    debugPrint("sigterm, exiting");
    exit(0);
  },);
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
          home: const HomeScreen(),
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