import 'types.dart';

class Emitter {
  final Map<LenisEvent, List<Function>> _events = {};

  void emit<T>(LenisEvent event, [T? arg]) {
    final callbacks = _events[event] ?? [];
    for (final callback in [...callbacks]) {
      if (arg != null) {
        callback(arg);
      } else {
        callback();
      }
    }
  }

  void Function() on(LenisEvent event, Function cb) {
    _events.putIfAbsent(event, () => []).add(cb);

    return () {
      _events[event]?.removeWhere((i) => i == cb);
    };
  }

  void off(LenisEvent event, Function callback) {
    _events[event]?.removeWhere((i) => i == callback);
  }

  void destroy() {
    _events.clear();
  }
}
