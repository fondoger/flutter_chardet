import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';

void main() {
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FutureBuilder<DecodingResult>(
        future: CharsetDetector.autoDecode(
          Uint8List.fromList(utf8.encode('Hello, charset world.')),
        ),
        builder: (context, snapshot) {
          return Text(snapshot.data?.string ?? '');
        },
      ),
    );
  }
}
