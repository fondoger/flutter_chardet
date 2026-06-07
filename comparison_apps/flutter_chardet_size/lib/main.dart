import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_chardet/flutter_chardet.dart';

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
        future: FlutterChardet.autoDecode(
          Uint8List.fromList(utf8.encode('Hello, charset world.')),
        ),
        builder: (context, snapshot) {
          return Text(snapshot.data?.text ?? '');
        },
      ),
    );
  }
}
