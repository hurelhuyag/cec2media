import 'dart:ffi' as ffi;

// ref: https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h#L76
// ignore: non_constant_identifier_names
final int EV_SYN = 0;
// ignore: non_constant_identifier_names
final int EV_KEY = 1;
// ignore: non_constant_identifier_names
final int EV_REL = 2;
// ignore: non_constant_identifier_names
final int EV_ABS = 3;

typedef LibUinputSetupC = ffi.Int32 Function();
typedef LibUinputSendKeyEventC = ffi.Int32 Function(ffi.Int32, ffi.Int32, ffi.Int32);
typedef LibUinputDestroyC = ffi.Int32 Function();

typedef LibUinputSetup = int Function();
typedef LibUinputSendKeyEvent = int Function(int, int, int);
typedef LibUinputDestroy = int Function();

class LibUinput {

  late final ffi.DynamicLibrary _lib;
  late final LibUinputSetup _setup;
  late final LibUinputSendKeyEvent _sendKeyEvent;
  late final LibUinputDestroy _destroy;

  LibUinput(String sharedLibraryPath) {
    _lib = ffi.DynamicLibrary.open(sharedLibraryPath);
    _setup = _lib.lookupFunction<LibUinputSetupC, LibUinputSetup>("setup");
    _sendKeyEvent = _lib.lookupFunction<LibUinputSendKeyEventC, LibUinputSendKeyEvent>("sendKeyEvent");
    _destroy = _lib.lookupFunction<LibUinputDestroyC, LibUinputDestroy>("destroy");
  }

  void setup() => _setup();

  void sendKeyEvent(int type, int code, int value) {
    _sendKeyEvent(type, code, value);
  }

  void destroy() => _destroy();
}