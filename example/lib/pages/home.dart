import 'package:jaspr/jaspr.dart';
@Import.onWeb('dart:html', show: [#window, #document])
import 'home.imports.dart';
import 'package:jaspr_lenis/jaspr_lenis.dart';

class Home extends StatefulComponent {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Lenis? _lenis;
  int? _rafId;

  @override
  void initState() {
    super.initState();
    Future(() {
      if (!mounted) return;

      print('Initializing Lenis...');

      final lenis = Lenis(LenisOptions(
        wrapper: window,
        content: document.documentElement,
        lerp: 0.1,
      ));

      _lenis = lenis;

      void raf(num time) {
        if (_lenis == null) return;
        _lenis!.raf(time);
        _rafId = window.requestAnimationFrame(raf);
      }

      _rafId = window.requestAnimationFrame(raf);

      _lenis?.on(LenisEvent.scroll, (e) {
        print('Scroll progress: ${e.progress.toStringAsFixed(3)}');
      });
    });
  }

  @override
  void dispose() {
    print('Disposing Lenis...');

    if (_rafId != null) {
      window.cancelAnimationFrame(_rafId!);
    }

    _lenis?.destroy();

    _rafId = null;
    _lenis = null;

    super.dispose();
  }

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield div(classes: 'lenis-wrapper', [
      section(
        styles: Styles.combine([
          Styles(height: Unit.vh(100), backgroundColor: Colors.cyan),
          Styles(
              justifyContent: JustifyContent.center,
              alignItems: AlignItems.center),
        ]),
        [
          h1(
              styles: Styles(fontSize: Unit.rem(4)),
              [text('Jaspr meets Lenis')]),
        ],
      ),
      section(
        styles: Styles.combine([
          Styles(height: Unit.vh(100), backgroundColor: Colors.purple),
          Styles(
              flexDirection: FlexDirection.column,
              justifyContent: JustifyContent.center,
              alignItems: AlignItems.center,
              gap: Gap(column: Unit.rem(2), row: Unit.rem(2))),
        ]),
        [
          h2(
              styles: Styles(color: Colors.white, fontSize: Unit.rem(3)),
              [text('Smooth Scrolling Activated!')]),
          p(
              styles: Styles(color: Colors.white),
              [text('Scroll down to see the effect.')]),
        ],
      ),
      section(
        styles: Styles.combine([
          Styles(height: Unit.vh(100), backgroundColor: Colors.orange),
          Styles(
              justifyContent: JustifyContent.center,
              alignItems: AlignItems.center),
        ]),
        [
          h2(styles: Styles(fontSize: Unit.rem(3)), [text('The End.')]),
        ],
      ),
    ]);
  }
}
