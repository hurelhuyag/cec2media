import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class GracefulShutdown extends StatefulWidget {
  const GracefulShutdown({super.key, required this.child});

  final Widget child;

  @override
  State<GracefulShutdown> createState() => _GracefulShutdownState();
}

class _GracefulShutdownState extends State<GracefulShutdown> {

  bool _shuttingDown = false;

  @override
  void initState() {
    super.initState();
    _listenForSignals();
  }

  Future<void> _handleExitSignal(ProcessSignal signal) async {
    if (_shuttingDown) {
      return;
    }
    debugPrint('Signal received: $signal');
    setState(() {
      _shuttingDown = true;
    });
    await Future.delayed(Duration(seconds: 0), () async {
      debugPrint('Exiting gracefully...');
      await SystemNavigator.pop();
    });
  }

  void _listenForSignals() {
    for (var signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
      signal.watch().listen(_handleExitSignal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _shuttingDown ? SizedBox.shrink() : widget.child;
  }
}