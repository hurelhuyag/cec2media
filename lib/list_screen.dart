import 'dart:convert';
import 'dart:io';

import 'package:cec2media/mpv_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return KeyboardListener(
      onKeyEvent: (e) {
        if (e is KeyUpEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      focusNode: FocusNode(),
      child: Scaffold(
        body: ListView.builder(
          physics: RangeMaintainingScrollPhysics(),
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            final name = file.path.substring(file.path.lastIndexOf("/")+1);
            return ListTile(
              autofocus: index == 0,
              onTap: () {
                if (file is Directory) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ListScreen(file),));
                  return;
                }
                if (file is File) {
                  handleFile(file);
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("We do nothing with ${file.runtimeType}")));
              },
              title: Text(name),
              subtitle: Text("${file.runtimeType}"),
            );
          },
        ),
      ),
    );
  }
}
