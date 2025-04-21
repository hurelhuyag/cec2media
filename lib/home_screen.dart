import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Set<String> _mountedDisks = {};
  List<String> _disks = [];

  void _listDisks() async {
    final mountedDisks = kDebugMode
        ? <String>{}
        : await Directory("/mnt/usb")
                .list()
                .map((event) => event.path.substring(event.path.lastIndexOf("/")+1),)
                .toSet();

    final diskDir = Directory("/dev/disk/by-label/");
    final disks = await diskDir
        .list()
        .map((event) => event.path.substring(event.path.lastIndexOf("/")+1),)
        .where((event) => event != "bootfs" && event != "rootfs",)
        .toList();
    disks.add("/");
    setState(() {
      _mountedDisks = mountedDisks;
      _disks = disks;
    });
  }

  StreamSubscription<FileSystemEvent>? _diskDirSub;

  void _watchDisks() {
    final diskDir = Directory("/dev/disk/by-label/");
    _diskDirSub?.cancel();
    _diskDirSub = diskDir.watch().listen((event) {
      debugPrint("/dev/disk/by-label/ ${event.type} ${event.type}");
      _listDisks();
    },);
  }

  @override
  void initState() {
    _listDisks();
    _watchDisks();
    super.initState();
  }

  @override
  void dispose() {
    debugPrint("home_screen.dispose()");
    _diskDirSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _disks.length,
        itemBuilder: (context, index) {
          final disk = _disks[index];
          final mounted = _mountedDisks.contains(disk);
          return ListTile(
            onTap: () {
              if (kDebugMode) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ListScreen(Directory("/media/hurlee/P2")),)
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ListScreen(Directory(disk == "/" ? "/" : "/mnt/usb/$disk")),)
                );
              }
            },
            title: Text(disk),
            subtitle: Text("Disk ${mounted ? '/Mounted/' : ''}"),
            trailing: mounted
              ? IconButton(
                onPressed: () async {
                  final process = await Process.start("sudo", ["/usr/bin/umount", "/mnt/usb/$disk"]);
                  process.stdout.transform(SystemEncoding().decoder).listen((event) => debugPrint("umount: $event"),);
                  process.stderr.transform(SystemEncoding().decoder).listen((event) => debugPrint("umount: $event"),);
                  process.exitCode.then((value) {
                    debugPrint("umount exit code $value");
                  },);
                },
                icon: Icon(Icons.close)
              )
              : null,
          );
        },
      ),
    );
  }
}