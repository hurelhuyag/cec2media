import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cec2media/models/block_devices.dart';
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

  List<BlockPartition> _disks = [];

  Future<void> _listDisks() async {
    final disks = await lsblk();
    final partitions = disks.map((e) => e.partitions,).expand((element) => element).where((element) => !element.boot).toList();
    setState(() {
      _disks = partitions;
    });
  }

  StreamSubscription<FileSystemEvent>? _devSub;

  void _watchDisks() {
    _devSub?.cancel();
    _devSub = Directory("/dev/").watch().listen((event) {
      if (event.path == "/dev/fuse" || event.path == "/dev/null") { // when ntfs partition mounted, this event comes continuously
        return;
      }
      debugPrint("/dev/ ${event.type} ${event.path}");
      _listDisks();
    },);
  }

  Future<bool> _mount(BlockPartition part) async {
    final mountPoint = part.label ?? part.uuid;
    final mkdirProcess = await Process.start("sudo", ["/usr/bin/mkdir", "-p", "/mnt/$mountPoint"]);
    final mkdirExitCode = await mkdirProcess.exitCode;
    debugPrint("mkdir exit code $mkdirExitCode");

    final process = await Process.start("sudo", ["/usr/bin/mount"/*, "-o", "uid=1000,gid=1000"*/, part.name, "/mnt/$mountPoint"]);
    process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("mount: $event"),);
    process.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("mount: $event"),);
    final exitCode = await process.exitCode;
    debugPrint("mount exit code $exitCode");

    await _listDisks();
    return exitCode == 0;
  }

  Future<bool> _unmount(BlockPartition part) async {
    final mountPoint = part.label ?? part.uuid;
    final process = await Process.start("sudo", ["/usr/bin/umount", "/mnt/$mountPoint"]);
    process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("umount: $event"),);
    process.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((event) => debugPrint("umount: $event"),);
    final exitCode = await process.exitCode;
    debugPrint("umount exit code $exitCode");

    final mkdirProcess = await Process.start("sudo", ["/usr/bin/rmdir", "/mnt/$mountPoint"]);
    final mkdirExitCode = await mkdirProcess.exitCode;
    debugPrint("rmdir exit code $mkdirExitCode");

    await _listDisks();
    return exitCode == 0;
  }

  @override
  void initState() {
    _listDisks();
    _watchDisks();
    super.initState();
  }

  @override
  void dispose() {
    debugPrint("disks_screen.dispose()");
    _devSub?.cancel();
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
                        if (disk.mountpoint == null) {
                          await _mount(disk);
                        }
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ListScreen(Directory(disk.mountpoint == "/" ? "/" : "/mnt/${disk.label ?? disk.uuid}")),
                              settings: RouteSettings(name: disk.label ?? disk.uuid)
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
                          Text("${disk.label ?? disk.uuid ?? disk.name} /${disk.fstype}/"),
                          Text(
                            "Available: ${disk.fsavail ?? '-'}, Total: ${disk.size}",
                            style: TextStyle(fontSize: Theme.of(context).textTheme.labelSmall!.fontSize, color: Theme.of(context).hintColor)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (disk.mountpoint != null && disk.mountpoint != "/")
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
          },
        ),
      ),
    );
  }
}