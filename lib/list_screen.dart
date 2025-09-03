import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cec2media/image_viewer.dart';
import 'package:cec2media/models/sort.dart';
import 'package:flutter/material.dart';

import 'mpv_player.dart';
import 'nav_path.dart';

final _random = math.Random();

class ListScreen extends StatefulWidget {
  const ListScreen(this.dir, {super.key});

  final Directory dir;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {

  Sort _sort = Sort.abc;
  List<FileSystemEntity> _files = [];

  void listDir() async {
    final files = await widget.dir.list().toList();
    _sortFiles();
    setState(() {
      _files = files;
    });
  }

  void _sortFiles() {
    switch(_sort) {
      case Sort.abc:
        _files.sort((a, b) => a.path.compareTo(b.path),);
        break;
      case Sort.modifiedDate:
        _files.sort((a, b) => -a.statSync().modified.compareTo(b.statSync().modified),);
        break;
      case Sort.random:
        _files.sort((a, b) => _random.nextInt(1000),);
        break;
    }
  }

  void handleFile(File file) async {
    final fileProcess = await Process.start("/usr/bin/file", ["--brief", "--mime-type", file.path]);
    final mimeType = (await fileProcess.stdout.transform(utf8.decoder).join()).trim();
    if (mimeType.startsWith("image/")) {
      showImage(file);
      return;
    }
    /*if (mimeType.startsWith("audio/")) { mpv doesn't show GUI if argument is audio file. which makes it hard to exit before audio finished
      if (mounted) {
        MpvPlayer.of(context).play(file);
      }
      return;
    }*/
    if (mimeType.startsWith("video/") || mimeType.trim() == "application/octet-stream") {
      if (mounted) {
        MpvPlayer.of(context).play(file);
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cant open a $mimeType file")));
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
        actions: [
          SegmentedButton<Sort>(
            segments: [
              ButtonSegment<Sort>(value: Sort.abc, label: Text("Abc")),
              ButtonSegment<Sort>(value: Sort.modifiedDate, label: Text("Date")),
              ButtonSegment<Sort>(value: Sort.random, label: Text("Random")),
            ],
            selected: {
              _sort
            },
            showSelectedIcon: true,
            onSelectionChanged: (val) {
              setState(() {
                _sort = val.first;
              });
              _sortFiles();
              setState(() {
              });
            },
          ),
        ],
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
