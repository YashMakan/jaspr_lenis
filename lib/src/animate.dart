import 'maths.dart';
import 'types.dart';

class Animate {
  bool isRunning = false;
  double value = 0;
  double from = 0;
  double to = 0;
  double currentTime = 0;

  double? lerp;
  double? duration;
  EasingFunction? easing;
  OnUpdateCallback? onUpdate;

  void advance(double deltaTime) {
    if (!isRunning) return;

    bool completed = false;

    if (duration != null && easing != null) {
      currentTime += deltaTime;
      final linearProgress = clamp(0, currentTime / duration!, 1);

      completed = linearProgress >= 1;
      final easedProgress = completed ? 1 : easing!(linearProgress);
      value = from + (to - from) * easedProgress;
    } else if (lerp != null) {
      value = damp(value, to, lerp! * 60, deltaTime);
      if (value.round() == to.round()) {
        value = to;
        completed = true;
      }
    } else {
      value = to;
      completed = true;
    }

    if (completed) {
      stop();
    }

    onUpdate?.call(value, completed);
  }

  void stop() {
    isRunning = false;
  }

  void fromTo(double from, double to, FromToOptions options) {
    this.from = value = from;
    this.to = to;
    lerp = options.lerp;
    duration = options.duration;
    easing = options.easing;
    currentTime = 0;
    isRunning = true;

    options.onStart?.call();
    onUpdate = options.onUpdate;
  }
}
