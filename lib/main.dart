import 'dart:ui';

import 'package:cec2media/home_screen.dart';
import 'package:cec2media/mpv_player.dart';
import 'package:flutter/material.dart';

void main() {
  debugPrint("flutter main");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MpvPlayerProvider(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          title: 'Medias',
          scrollBehavior: const MyCustomScrollBehavior(),
          //themeMode: ThemeMode.dark,
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