import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'list_screen.dart';
import 'nav_path.dart';

class DisksScreen extends StatefulWidget {
  const DisksScreen({super.key});

  @override
  State<DisksScreen> createState() => _DisksScreenState();
}

class _DisksScreenState extends State<DisksScreen> {

  Set<String> _mountedDisks = {};
  List<String> _disks = [];

  Future<void> _listDisks() async {
    final mountedDisks = await _listMounted();
    debugPrint("mounted disks ${mountedDisks.join(", ")}");

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
  StreamSubscription<FileSystemEvent>? _mountDirSub;

  void _watchDisks() {
    _diskDirSub?.cancel();
    _diskDirSub = Directory("/dev/disk/by-label/").watch().listen((event) {
      debugPrint("/dev/disk/by-label/ ${event.type} ${event.path}");
      _listDisks();
    },);
    /*_mountDirSub?.cancel();
    _mountDirSub = Directory("/mnt").watch().listen((event) {
      debugPrint("/mnt/ ${event.type} ${event.path}");
      _listDisks();
    },);*/
  }

  Future<bool> _mount(String disk) async {
    final mkdirProcess = await Process.start("sudo", ["/usr/bin/mkdir", "-p", "/mnt/$disk"]);
    final mkdirExitCode = await mkdirProcess.exitCode;
    debugPrint("mkdir exit code $mkdirExitCode");

    final process = await Process.start("sudo", ["/usr/bin/mount"/*, "-o", "uid=1000,gid=1000"*/, "-L", disk, "/mnt/$disk"]);
    process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("mount: $event"),);
    process.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("mount: $event"),);
    final exitCode = await process.exitCode;
    debugPrint("mount exit code $exitCode");

    await _listDisks();
    return exitCode == 0;
  }

  Future<bool> _unmount(String disk) async {
    final process = await Process.start("sudo", ["/usr/bin/umount", "/mnt/$disk"]);
    process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("umount: $event"),);
    process.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("umount: $event"),);
    final exitCode = await process.exitCode;
    debugPrint("umount exit code $exitCode");

    final mkdirProcess = await Process.start("sudo", ["/usr/bin/rmdir", "/mnt/$disk"]);
    final mkdirExitCode = await mkdirProcess.exitCode;
    debugPrint("rmdir exit code $mkdirExitCode");

    await _listDisks();
    return exitCode == 0;
  }

  Future<Set<String>> _listMounted() async {
    final process = await Process.start("/usr/bin/lsblk", ["-o", "LABEL,MOUNTPOINT"]);
    final lines = await process.stdout.transform(utf8.decoder).transform(LineSplitter())
        .map((event) => event.trim())
        .where((event) => event.isNotEmpty,)
        .toList();
    final mountPointIndex = lines[0].indexOf("MOUNTPOINT");
    Set<String> mountedDisks = {};
    for (int i=1; i<lines.length; i++) {
      final line = lines[i];
      final notMounted = line.length < mountPointIndex;
      final label = notMounted ? line : line.substring(0, mountPointIndex - 1).trim();
      if (!notMounted) {
        mountedDisks.add(label);
      }
    }
    final exitCode = await process.exitCode;
    debugPrint("lsblk exit code $exitCode");
    return mountedDisks;
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
    _mountDirSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: NavPath(),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        thickness: 10,
        radius: Radius.circular(5),
        child: ListView.builder(
          primary: true,
          itemCount: _disks.length,
          itemBuilder: (context, index) {
            final disk = _disks[index];
            final diskMounted = _mountedDisks.contains(disk);
            return Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      if (kDebugMode) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ListScreen(Directory("/media/hurlee/P2")),
                            settings: RouteSettings(name: "P2")
                          )
                        );
                      } else {
                        if (!diskMounted && disk != "/") {
                          await _mount(disk);
                        }
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ListScreen(Directory(disk == "/" ? "/" : "/mnt/$disk")),
                              settings: RouteSettings(name: disk)
                            )
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(disk),
                          Text("Disk ${diskMounted ? '/Mounted/' : ''}", style: TextStyle(fontSize: Theme.of(context).textTheme.labelSmall!.fontSize, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (diskMounted && disk != "/")
                  InkWell(
                    onTap: () {
                      _unmount(disk);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Icon(Icons.eject, size: 50,),
                    )
                  )
              ],
            );
            return ListTile(
              onTap: () {
                if (kDebugMode) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ListScreen(Directory("/media/hurlee/P2")), settings: RouteSettings(name: "P2"))
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ListScreen(Directory(disk == "/" ? "/" : "/mnt/usb/$disk")), settings: RouteSettings(name: disk))
                  );
                }
              },
              title: Text(disk),
              subtitle: Text("Disk ${diskMounted ? '/Mounted/' : ''}"),
              trailing: diskMounted
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
      ),
    );
  }
}