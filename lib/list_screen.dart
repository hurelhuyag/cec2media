import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'mpv_player.dart';
import 'nav_path.dart';

class ListScreen extends StatefulWidget {
  const ListScreen(this.dir, {super.key});

  final Directory dir;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {

  List<FileSystemEntity> _files = [];

  void listDir() async {
    final files = await widget.dir.list().toList();
    files.sort((a, b) => a.path.compareTo(b.path),);
    setState(() {
      _files = files;
    });
  }

  void handleFile(File file) async {
    final fileProcess = await Process.start("/usr/bin/file", ["--brief", "--mime-type", file.path]);
    final result = await fileProcess.stdout.transform(utf8.decoder).join();
    if (!result.trim().startsWith("video/") && result.trim() != "application/octet-stream") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Not A Video")));
      }
      return;
    }

    if (mounted) {
      MpvPlayer.of(context).play(file);
    }
  }

  @override
  void initState() {
    listDir();
    super.initState();
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
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            final name = file.path.substring(file.path.lastIndexOf("/")+1);
            return ListTile(
              autofocus: index == 0,
              onTap: () {
                if (file is Directory) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ListScreen(file), settings: RouteSettings(name: name)));
                  return;
                }
                if (file is File) {
                  handleFile(file);
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("We do nothing with ${file.runtimeType}")));
              },
              title: Text(name),
              subtitle: Text(file is File ? file.lengthSync().h : file is Directory ? 'Directory' : file is Link ? 'Link to ${file.targetSync()}' : 'Unknown'),
            );
          },
        ),
      ),
    );
  }
}

extension IntHumanReadable on int {
  /// Human readable file size
  String get h {
    if (this < 1024) {
      return '${this}B';
    }
    if (this < 1024*1024) {
      return '${this~/1024}kB';
    }
    if (this < 1024*1024*1024) {
      return '${this/1024~/1024}MB';
    }
    return '${this/1024/1024~/1024}GB';
  }
}
