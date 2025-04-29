import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cec2media/disks_screen.dart';
import 'package:flutter/material.dart';

Process? _youtubeProcess;
Process? _terminalProcess;

int w = 1920, h = 1080;

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {

  FocusNode? _focusNode;

  @override
  Widget build(BuildContext context) {
    final dim = MediaQuery.sizeOf(context);
    w = dim.width.toInt();
    h = dim.height.toInt();
    debugPrint("Launcher size: ${w}x$h");
    return Scaffold(
      body: GridView.count(
        primary: true,
        crossAxisCount: 3,
        children: [
          _buildMenuItem(context, "Youtube", Icons.tv, () => _launchYoutube(context, w, h), true),
          _buildMenuItem(context, "Media", Icons.video_file, () => _launchMedia(context),),
          _buildMenuItem(context, "Terminal", Icons.terminal, _launchTerminal),
          _buildMenuItem(context, "Chromium", Icons.web, () => _launchBrowser(w, h),),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, void Function() onTap, [bool autofocus = false]) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        focusNode: autofocus ? _focusNode : null,
        autofocus: autofocus,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0) ,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  child: Icon(icon)
                )
              ),
              Text(title, style: Theme.of(context).textTheme.titleMedium,),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchMedia(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => DisksScreen(), settings: RouteSettings(name: "Disks")));
  }

  Future<void> _launchYoutube(BuildContext context, int w, int h) async {
    _showLoadingDialog(context, Duration(seconds: 10));
    _youtubeProcess?.kill();
    _youtubeProcess = await Process.start("/usr/bin/chromium", [
      "--kiosk", "--window-position=0,0", "--window-size=$w,$h",
      "--ozone-platform=wayland", "--enable-features=UseOzonePlatform",
      "--enable-features=VaapiVideoDecoder", "--enable-zero-copy", "--enable-gpu-rasterization",
      "--user-data-dir=/home/pi/youtubetv",
      "--user-agent=\"Mozilla/5.0 (PS4; Leanback Shell) Gecko/20100101 Firefox/65.0 LeanbackShell/01.00.01.75 Sony PS4/ (PS4, , no, CH)\"",
      "--force-dark-mode", "--enable-features=WebUIDarkMode", "--no-default-browser-check", "--disable-translate",
      "--fast", "--fast-start", "--disable-features=TranslateUI", "--password-store=basic", "--no-first-run",
      "--force-dev-mode-highlighting",
      "--load-extension=${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/chromium-close-extension",
      "--app=https://www.youtube.com/tv"
    ]);
    _youtubeProcess?.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("youtube: $event"),);
    _youtubeProcess?.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("youtube: $event"),);
    _youtubeProcess?.exitCode.then((value) {
      debugPrint("youtube: process finished with exit code: $value");
      _youtubeProcess = null;
    },);
  }

  Future<void> _launchBrowser(int w, int h) async {
    _youtubeProcess?.kill();
    _youtubeProcess = await Process.start("/usr/bin/chromium", ["--window-position=0,0", "--window-size=$w,$h"]);
    _youtubeProcess?.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("chromium: $event"),);
    _youtubeProcess?.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("chromium: $event"),);
    _youtubeProcess?.exitCode.then((value) {
      debugPrint("chromium: process finished with exit code: $value");
      _youtubeProcess = null;
    },);
  }

  Future<void> _launchTerminal() async {
    _terminalProcess?.kill();
    //_terminalProcess = await Process.start("/usr/bin/weston-terminal", []);
    _terminalProcess = await Process.start("/usr/bin/foot", []);
    _terminalProcess?.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("terminal: $event"),);
    _terminalProcess?.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("terminal: $event"),);
    _terminalProcess?.exitCode.then((value) {
      debugPrint("terminal: process finished with exit code: $value");
      _terminalProcess = null;
    },);
  }

  Future<void> _showLoadingDialog(BuildContext context, Duration duration) async {
    final timer = Timer(duration, () => Navigator.of(context).pop(),);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(100),
          child: SizedBox(
            width: 40,
            height: 40,
            child: FittedBox(
                child: CircularProgressIndicator()
            ),
          ),
        ),
      ),
    );
    timer.cancel();

    // Somehow flutter lost focus. So force to focus something
    if (context.mounted) {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }
}
