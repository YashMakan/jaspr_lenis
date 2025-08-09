import 'package:jaspr/jaspr.dart';

@Import.onWeb('dart:html', show: [
  #window,
  #Element,
  #Event,
  #MouseEvent,
  #KeyboardEvent,
  #TouchEvent,
  #WheelEvent,
  #EventTarget,
  #document,
  #Window,
  #ResizeObserver,
])
export 'html.imports.dart';