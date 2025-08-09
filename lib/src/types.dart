import 'html.dart' as html;
import 'lenis.dart';

typedef EasingFunction = double Function(double t);
typedef OnUpdateCallback = void Function(double value, bool completed);
typedef OnStartCallback = void Function();
typedef ScrollCallback = void Function(Lenis lenis);
typedef VirtualScrollCallback = void Function(VirtualScrollData data);

class FromToOptions {
  final double? lerp;
  final double? duration;
  final EasingFunction? easing;
  final OnStartCallback? onStart;
  final OnUpdateCallback? onUpdate;

  FromToOptions({
    this.lerp,
    this.duration,
    this.easing,
    this.onStart,
    this.onUpdate,
  });
}

typedef UserData = Map<String, dynamic>;

enum ScrollingState { stopped, native, smooth }

enum LenisEvent { scroll, virtualScroll }

class VirtualScrollData {
  final double deltaX;
  final double deltaY;
  final dynamic event;

  VirtualScrollData({
    required this.deltaX,
    required this.deltaY,
    required this.event,
  });
}

enum Orientation { vertical, horizontal }

enum GestureOrientation { vertical, horizontal, both }

class ScrollToOptions {
  final double offset;
  final bool immediate;
  final bool lock;
  final double? duration;
  final EasingFunction? easing;
  final double? lerp;
  final void Function(Lenis lenis)? onStart;
  final void Function(Lenis lenis)? onComplete;
  final bool force;
  final bool programmatic;
  final UserData? userData;

  ScrollToOptions({
    this.offset = 0,
    this.immediate = false,
    this.lock = false,
    this.duration,
    this.easing,
    this.lerp,
    this.onStart,
    this.onComplete,
    this.force = false,
    this.programmatic = true,
    this.userData,
  });
}

class LenisOptions {
  final dynamic wrapper;
  final dynamic content;
  final dynamic eventsTarget;
  final bool smoothWheel;
  final bool syncTouch;
  final double syncTouchLerp;
  final double touchInertiaExponent;
  final double? duration;
  final EasingFunction? easing;
  final double lerp;
  final bool infinite;
  final Orientation orientation;
  final GestureOrientation gestureOrientation;
  final double touchMultiplier;
  final double wheelMultiplier;
  final bool autoResize;
  final bool Function(dynamic node)? prevent;
  final bool Function(VirtualScrollData data)? virtualScroll;
  final bool overscroll;
  final bool autoRaf;
  final dynamic anchors;
  final bool autoToggle;
  final bool allowNestedScroll;
  final bool experimentalNaiveDimensions;

  LenisOptions({
    dynamic wrapper,
    dynamic content,
    dynamic eventsTarget,
    this.smoothWheel = true,
    this.syncTouch = false,
    this.syncTouchLerp = 0.075,
    this.touchInertiaExponent = 1.7,
    this.duration,
    this.easing,
    this.lerp = 0.1,
    this.infinite = false,
    this.orientation = Orientation.vertical,
    this.gestureOrientation = GestureOrientation.vertical,
    this.touchMultiplier = 1.0,
    this.wheelMultiplier = 1.0,
    this.autoResize = true,
    this.prevent,
    this.virtualScroll,
    this.overscroll = true,
    this.autoRaf = false,
    this.anchors = false,
    this.autoToggle = false,
    this.allowNestedScroll = false,
    this.experimentalNaiveDimensions = false,
  }) : wrapper = wrapper ?? html.window,
       content = content ?? html.window.document.documentElement!,
       eventsTarget = eventsTarget ?? (wrapper ?? html.window);
}
