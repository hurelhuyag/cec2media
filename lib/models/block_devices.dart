import 'dart:convert';
import 'dart:io';

Future<List<BlockDevice>> lsblk() async {
  final process = await Process.start("/usr/bin/lsblk", ["-o", "NAME,LABEL,FSTYPE,SIZE,FSAVAIL,MOUNTPOINT,UUID", "--json", "--paths"]);
  final res = await process.stdout.transform(utf8.decoder).join();
  final resJson = jsonDecode(res) as Map<String, dynamic>;
  final blockDevicesJson = resJson["blockdevices"] as List<dynamic>;
  final blockDevices = blockDevicesJson.map((e) => BlockDevice.fromJson(e)).toList();
  return blockDevices;
}

class BlockDevice {

  final String name;
  final List<BlockPartition> partitions;

  const BlockDevice(this.name, this.partitions);

  factory BlockDevice.fromJson(Map<String, dynamic> json) {
    final name = json["name"] as String;
    final partitions = json["children"] as List<dynamic>?;
    return BlockDevice(name, partitions?.map((e) => BlockPartition.fromJson(e)).toList() ?? []);
  }
}

class BlockPartition {
  final String name;
  final String? label;
  final String? fstype;
  final String size;
  final String? fsavail;
  final String? mountpoint;
  final bool boot;
  final String? uuid;

  const BlockPartition(this.name, this.label, this.fstype, this.size, this.fsavail, this.mountpoint, this.boot, this.uuid);

  factory BlockPartition.fromJson(Map<String, dynamic> json) {
    final mountpoint = json["mountpoint"] as String?;
    var boot = false;
    if (mountpoint != null && mountpoint.startsWith("/boot/")) {
      boot = true;
    }
    return BlockPartition(json["name"], json["label"], json["fstype"], json["size"], json["fsavail"], mountpoint, boot, json["uuid"]);
  }
}

Future<void> main() async {
  print("main");
  var res = await lsblk();
  /*for (var a in res) {
    print(a.name);
    for (var b in a.partitions) {
      print("\t${b.name}, ${b.label}, ${b.fstype}, ${b.size}, ${b.fsavail}, ${b.mountpoint}");
    }
  }*/

  var parts = res.map((e) => e.partitions,).expand((element) => element,).toList();
  for (var b in parts) {
    print("\t${b.name}, ${b.label}, ${b.fstype}, ${b.size}, ${b.fsavail}, ${b.mountpoint}, ${b.uuid}");
  }
}

