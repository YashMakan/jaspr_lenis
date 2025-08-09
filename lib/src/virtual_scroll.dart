import 'html.dart' as html;
import 'dart:math' as math;
import 'emitter.dart';
import 'types.dart';

const double _lineHeight = 100 / 6;

class VirtualScroll {
  final dynamic _element;
  final double _wheelMultiplier;
  final double _touchMultiplier;

  final Emitter _emitter = Emitter();
  math.Point<double> _touchStart = math.Point(0, 0);
  math.Point<double> _lastDelta = math.Point(0, 0);
  math.Point<double> _windowSize = math.Point(0, 0);

  VirtualScroll(
    this._element, {
    double wheelMultiplier = 1.0,
    double touchMultiplier = 1.0,
  }) : _wheelMultiplier = wheelMultiplier,
       _touchMultiplier = touchMultiplier {
    html.window.addEventListener('resize', _onWindowResize);
    _onWindowResize(null);

    _element.addEventListener('wheel', _onWheel);
    _element.addEventListener('touchstart', _onTouchStart);
    _element.addEventListener('touchmove', _onTouchMove);
    _element.addEventListener('touchend', _onTouchEnd);
  }

  void Function() on(LenisEvent event, VirtualScrollCallback callback) {
    return _emitter.on(event, callback);
  }

  void destroy() {
    _emitter.destroy();
    html.window.removeEventListener('resize', _onWindowResize);
    _element.removeEventListener('wheel', _onWheel);
    _element.removeEventListener('touchstart', _onTouchStart);
    _element.removeEventListener('touchmove', _onTouchMove);
    _element.removeEventListener('touchend', _onTouchEnd);
  }

  void _onWindowResize(dynamic e) {
    _windowSize = math.Point(
      html.window.innerWidth!.toDouble(),
      html.window.innerHeight!.toDouble(),
    );
  }

  void _onTouchStart(dynamic e) {
    final event = e as html.TouchEventOrStubbed;

    final touch = event.targetTouches?.isNotEmpty ?? false
        ? event.targetTouches![0]
        : null;
    if (touch == null) return;

    _touchStart = math.Point(
      touch.client.x.toDouble(),
      touch.client.y.toDouble(),
    );
    _lastDelta = math.Point(0, 0);

    _emitter.emit(
      LenisEvent.scroll,
      VirtualScrollData(deltaX: 0, deltaY: 0, event: event),
    );
  }

  void _onTouchMove(dynamic e) {
    final event = e as html.TouchEventOrStubbed;
    final touch = event.targetTouches?.isNotEmpty ?? false
        ? event.targetTouches![0]
        : null;
    if (touch == null) return;

    final client = touch.client;
    final deltaX = -(client.x - _touchStart.x) * _touchMultiplier;
    final deltaY = -(client.y - _touchStart.y) * _touchMultiplier;

    _touchStart = math.Point(client.x.toDouble(), client.y.toDouble());
    _lastDelta = math.Point(deltaX, deltaY);

    _emitter.emit(
      LenisEvent.scroll,
      VirtualScrollData(deltaX: deltaX, deltaY: deltaY, event: event),
    );
  }

  void _onTouchEnd(dynamic e) {
    final event = e as html.TouchEventOrStubbed;
    _emitter.emit(
      LenisEvent.scroll,
      VirtualScrollData(
        deltaX: _lastDelta.x,
        deltaY: _lastDelta.y,
        event: event,
      ),
    );
  }

  void _onWheel(dynamic e) {
    final event = e as html.WheelEventOrStubbed;

    double deltaX = event.deltaX.toDouble();
    double deltaY = event.deltaY.toDouble();

    if (event.deltaMode == 1) {
      // LINE
      deltaX *= _lineHeight;
      deltaY *= _lineHeight;
    } else if (event.deltaMode == 2) {
      // PAGE
      deltaX *= _windowSize.x;
      deltaY *= _windowSize.y;
    }

    deltaX *= _wheelMultiplier;
    deltaY *= _wheelMultiplier;

    _emitter.emit(
      LenisEvent.scroll,
      VirtualScrollData(deltaX: deltaX, deltaY: deltaY, event: event),
    );
  }
}
