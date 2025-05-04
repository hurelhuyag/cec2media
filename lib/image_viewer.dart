import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';

Future<void> showImage(File selected) async {
  final process = await Process.start(
      "/usr/bin/imv-wayland",
      [selected.parent.path, "-n", selected.path],
      environment: {
        "imv_config": "${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/imv.conf"
      }
  );
  process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("imv: $event"),);
  process.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("imv: $event"),);
  final exitCode = await process.exitCode;
  debugPrint("imv exited with $exitCode");
}

extension FileName on File {
  String get name {
    final i = path.lastIndexOf("/");
    return path.substring(i+1);
  }
}