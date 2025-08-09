import 'dart:async';

Function debounce(Function(List<dynamic>) callback, Duration delay) {
  Timer? timer;

  return (List<dynamic> args) {
    timer?.cancel();
    timer = Timer(delay, () {
      callback(args);
    });
  };
}
