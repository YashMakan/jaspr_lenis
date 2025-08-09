import 'dart:async';
import 'html.dart' as html;
import 'dart:math' as math;

import 'animate.dart';
import 'dimensions.dart';
import 'emitter.dart';
import 'maths.dart' as m;
import 'types.dart';
import 'virtual_scroll.dart';

double _defaultEasing(double t) => math.min(1, 1.001 - math.pow(2, -10 * t));

class Lenis {
  // State
  ScrollingState _scrollingState = ScrollingState.stopped;
  bool _isStopped = false;
  bool isLocked = false;
  bool _preventNextNativeScrollEvent = false;
  Timer? _resetVelocityTimeout;
  int? _rafId;

  // Public properties
  bool isTouching = false;
  double time = 0;
  UserData userData = {};
  double lastVelocity = 0;
  double velocity = 0;
  int direction = 0; // -1, 0, 1
  final LenisOptions options;
  double targetScroll = 0;
  double animatedScroll = 0;

  // Private
  final Animate _animate = Animate();
  final Emitter _emitter = Emitter();
  late final Dimensions dimensions;
  late final VirtualScroll _virtualScroll;

  Lenis([LenisOptions? options]) : options = options ?? LenisOptions() {
    html.window.console.log('Lenis for Dart initializing...');

    dimensions = Dimensions(
      wrapper: this.options.wrapper,
      content: this.options.content,
      autoResize: this.options.autoResize,
    );
    _virtualScroll = VirtualScroll(
      this.options.eventsTarget,
      touchMultiplier: this.options.touchMultiplier,
      wheelMultiplier: this.options.wheelMultiplier,
    );

    targetScroll = animatedScroll = actualScroll;
    _updateClassName();

    this.options.wrapper.addEventListener('scroll', _onNativeScroll);
    _virtualScroll.on(LenisEvent.scroll, _onVirtualScroll);

    if (this.options.autoRaf) {
      _rafId = html.window.requestAnimationFrame(raf);
    }
  }

  void destroy() {
    _emitter.destroy();
    options.wrapper.removeEventListener('scroll', _onNativeScroll);
    _virtualScroll.destroy();
    dimensions.destroy();
    if (_rafId != null) {
      html.window.cancelAnimationFrame(_rafId!);
      _rafId = null;
    }
    _cleanUpClassName();
  }

  void raf(num time) {
    final double deltaTime =
        (time.toDouble() - (this.time > 0 ? this.time : time.toDouble())) /
        1000.0;
    this.time = time.toDouble();

    _animate.advance(deltaTime);

    if (options.autoRaf) {
      _rafId = html.window.requestAnimationFrame(raf);
    }
  }

  void _onNativeScroll(dynamic e) {
    if (_preventNextNativeScrollEvent) {
      _preventNextNativeScrollEvent = false;
      return;
    }

    if (_scrollingState == ScrollingState.stopped ||
        _scrollingState == ScrollingState.native) {
      final lastScroll = animatedScroll;
      animatedScroll = targetScroll = actualScroll;
      velocity = animatedScroll - lastScroll;
      direction = velocity.sign.toInt();
      lastVelocity = velocity;

      if (!_isStopped) {
        _setScrollingState(ScrollingState.native);
      }
      _emit();

      _resetVelocityTimeout?.cancel();
      if (velocity != 0) {
        _resetVelocityTimeout = Timer(Duration(milliseconds: 400), () {
          lastVelocity = velocity;
          velocity = 0;
          _setScrollingState(ScrollingState.stopped);
          _emit();
        });
      }
    }
  }

  void _onVirtualScroll(VirtualScrollData data) {
    if (options.virtualScroll?.call(data) == false) return;

    final event = data.event;

    if (isStopped || isLocked) {
      if (event.cancelable ?? false) event.preventDefault();
      return;
    }

    isTouching = event.type.contains('touch');

    bool isSmooth =
        (options.smoothWheel && event is html.WheelEventOrStubbed) ||
        (options.syncTouch && isTouching);

    if (!isSmooth) {
      _setScrollingState(ScrollingState.native);
      _animate.stop();
      return;
    }

    if (event.cancelable ?? false) event.preventDefault();

    double delta = data.deltaY;
    if (options.gestureOrientation == GestureOrientation.horizontal) {
      delta = data.deltaX;
    } else if (options.gestureOrientation == GestureOrientation.both) {
      delta = data.deltaY.abs() > data.deltaX.abs() ? data.deltaY : data.deltaX;
    }

    final isTouchEnd = isTouching && event.type == 'touchend';
    final hasTouchInertia = isTouchEnd && velocity.abs() > 1;

    if (hasTouchInertia) {
      delta = velocity * options.touchInertiaExponent;
    }

    scrollTo(
      targetScroll + delta,
      options: ScrollToOptions(
        programmatic: false,
        lerp: (isTouchEnd) ? options.syncTouchLerp : options.lerp,
        duration: options.duration,
        easing: options.easing,
      ),
    );
  }

  void resize() {
    dimensions.resize();
    animatedScroll = targetScroll = actualScroll;
    _emit();
  }

  void start() {
    if (!_isStopped) return;
    _isStopped = false;
    _reset();
  }

  void stop() {
    if (_isStopped) return;
    _isStopped = true;
    _animate.stop();
    _reset();
  }

  void _reset() {
    isLocked = false;
    _setScrollingState(ScrollingState.stopped);
    animatedScroll = targetScroll = actualScroll;
    lastVelocity = velocity = 0;
    _animate.stop();
  }

  void scrollTo(dynamic target, {ScrollToOptions? options}) {
    final opts = options ?? ScrollToOptions();
    if ((isStopped || isLocked) && !opts.force) return;

    double? targetValue;
    if (target is num) {
      targetValue = target.toDouble();
    } else if (target is String) {
      if (['top', 'left', 'start'].contains(target)) {
        targetValue = 0;
      } else if (['bottom', 'right', 'end'].contains(target)) {
        targetValue = limit;
      } else {
        final node = html.document.querySelector(target);
        if (node != null) {
          final rect = node.getBoundingClientRect();
          targetValue = (isHorizontal ? rect.left : rect.top) + animatedScroll;
        }
      }
    } else if (target is html.ElementOrStubbed) {
      final rect = target.getBoundingClientRect();
      targetValue = (isHorizontal ? rect.left : rect.top) + animatedScroll;
    }

    if (targetValue == null) return;
    targetValue += opts.offset;
    targetValue = m.clamp(0, targetValue, limit).toDouble();

    if (opts.immediate) {
      animatedScroll = targetScroll = targetValue;
      _setScroll(targetValue);
      _preventNextNativeScrollEvent = true;
      _reset();
      _emit();
      opts.onComplete?.call(this);
      return;
    }

    if (!opts.programmatic) {
      targetScroll = targetValue;
    }

    _animate.fromTo(
      animatedScroll,
      targetValue,
      FromToOptions(
        duration: opts.duration ?? this.options.duration,
        easing: opts.easing ?? this.options.easing ?? _defaultEasing,
        lerp: opts.lerp ?? this.options.lerp,
        onStart: () {
          if (opts.lock) isLocked = true;
          _setScrollingState(ScrollingState.smooth);
          opts.onStart?.call(this);
        },
        onUpdate: (value, completed) {
          _setScrollingState(ScrollingState.smooth);

          lastVelocity = velocity;
          velocity = value - animatedScroll;
          direction = velocity.sign.toInt();

          animatedScroll = value;
          _setScroll(scroll);

          if (opts.programmatic) {
            targetScroll = value;
          }

          if (!completed) _emit();

          if (completed) {
            _reset();
            _emit();
            opts.onComplete?.call(this);
            _preventNextNativeScrollEvent = true;
          }
        },
      ),
    );
  }

  void _setScroll(double value) {
    if (isHorizontal) {
      if (options.wrapper is html.WindowOrStubbed) {
        (options.wrapper as html.WindowOrStubbed).scrollTo(
          value.toInt(),
          (options.wrapper as html.WindowOrStubbed).scrollY.toInt(),
        );
      } else {
        (options.wrapper as html.ElementOrStubbed).scrollLeft = value.toInt();
      }
    } else {
      if (options.wrapper is html.WindowOrStubbed) {
        (options.wrapper as html.WindowOrStubbed).scrollTo(
          (options.wrapper as html.WindowOrStubbed).scrollX.toInt(),
          value.toInt(),
        );
      } else {
        (options.wrapper as html.ElementOrStubbed).scrollTop = value.toInt();
      }
    }
  }

  void _emit() => _emitter.emit(LenisEvent.scroll, this);

  void Function() on(LenisEvent event, ScrollCallback callback) {
    return _emitter.on(event, callback);
  }

  dynamic get rootElement => (options.wrapper == html.window)
      ? html.window.document.documentElement!
      : options.wrapper as html.ElementOrStubbed;

  double get limit {
    if (isHorizontal) {
      return dimensions.limit.x.toDouble();
    } else {
      return dimensions.limit.y.toDouble();
    }
  }

  bool get isHorizontal => options.orientation == Orientation.horizontal;

  double get actualScroll {
    final wrapper = options.wrapper;
    if (wrapper is html.WindowOrStubbed) {
      return isHorizontal
          ? wrapper.scrollX.toDouble()
          : wrapper.scrollY.toDouble();
    } else {
      final el = wrapper as html.ElementOrStubbed;
      return isHorizontal ? el.scrollLeft.toDouble() : el.scrollTop.toDouble();
    }
  }

  double get scroll {
    return options.infinite ? m.modulo(animatedScroll, limit) : animatedScroll;
  }

  double get progress => limit == 0 ? 1 : scroll / limit;

  ScrollingState get scrollingState => _scrollingState;

  bool get isScrolling => _scrollingState != ScrollingState.stopped;
  bool get isSmooth => _scrollingState == ScrollingState.smooth;
  bool get isStopped => _isStopped;

  void _setScrollingState(ScrollingState value) {
    if (_scrollingState != value) {
      _scrollingState = value;
      _updateClassName();
    }
  }

  String get className {
    var names = ['lenis'];
    if (isStopped) names.add('lenis-stopped');
    if (isLocked) names.add('lenis-locked');
    if (isScrolling) names.add('lenis-scrolling');
    if (isSmooth) names.add('lenis-smooth');
    return names.join(' ');
  }

  void _updateClassName() {
    _cleanUpClassName();
    rootElement.className = '${rootElement.className} $className'.trim();
  }

  void _cleanUpClassName() {
    rootElement.className = rootElement.className
        .replaceAll(RegExp(r'lenis(-\w+)?'), '')
        .trim();
  }
}
