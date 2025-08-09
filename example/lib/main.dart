import 'package:example/pages/home.dart';
import 'package:jaspr/server.dart';

import 'app.dart';

import 'jaspr_options.dart';

void main() {
  Jaspr.initializeApp(
    options: defaultJasprOptions,
  );

  runApp(Document(
    title: 'example',
    styles: [
      css.import('https://fonts.googleapis.com/css?family=Roboto'),
      css('html, body').styles(
        height: 100.percent,
        overflow: Overflow.hidden,
      ),
      css('*').styles(
        padding: Padding.zero,
        margin: Margin.zero,
      ),
      css('h1').styles(
        margin: Margin.unset,
        fontSize: 4.rem,
      ),
    ],
    body: Home(),
  ));
}
