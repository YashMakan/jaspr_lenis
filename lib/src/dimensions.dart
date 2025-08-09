import 'html.dart' as html;
import 'dart:math' as math;
import 'debounce.dart';

class Dimensions {
  double width = 0;
  double height = 0;
  double scrollHeight = 0;
  double scrollWidth = 0;

  final dynamic _wrapper;
  final dynamic _content;

  Function? _debouncedResize;
  dynamic _wrapperResizeObserver;
  dynamic _contentResizeObserver;

  Dimensions({
    required dynamic wrapper,
    required dynamic content,
    bool autoResize = true,
    int debounceValue = 250,
  }) : _wrapper = wrapper,
       _content = content {
    if (autoResize) {
      _debouncedResize = debounce(
        (_) => resize(),
        Duration(milliseconds: debounceValue),
      );

      if (_wrapper is html.WindowOrStubbed) {
        html.window.addEventListener(
          'resize',
          (event) => _debouncedResize!([]),
        );
      } else {
        _wrapperResizeObserver = html.ResizeObserver(
          (entries, observer) => _debouncedResize!([]),
        );
        _wrapperResizeObserver!.observe(_wrapper as html.ElementOrStubbed);
      }

      _contentResizeObserver = html.ResizeObserver(
        (entries, observer) => _debouncedResize!([]),
      );
      print("observe content::$_content;");
      _contentResizeObserver!.observe(_content);
    }

    resize();
  }

  void destroy() {
    _wrapperResizeObserver?.disconnect();
    _contentResizeObserver?.disconnect();
  }

  void resize() {
    onWrapperResize();
    onContentResize();
  }

  void onWrapperResize() {
    if (_wrapper is html.WindowOrStubbed) {
      width = html.window.innerWidth!.toDouble();
      height = html.window.innerHeight!.toDouble();
    } else {
      final el = _wrapper as html.ElementOrStubbed;
      width = el.clientWidth.toDouble();
      height = el.clientHeight.toDouble();
    }
  }

  void onContentResize() {
    final el = _content;
    print("check::$el;");
    scrollHeight = el.scrollHeight.toDouble();
    scrollWidth = el.scrollWidth.toDouble();
  }

  math.Point<double> get limit {
    return math.Point(scrollWidth - width, scrollHeight - height);
  }
}
