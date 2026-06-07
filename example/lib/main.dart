import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_chardet/flutter_chardet.dart';

void main() {
  runApp(const CharsetExampleApp());
}

class CharsetExampleApp extends StatelessWidget {
  const CharsetExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_chardet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const CharsetHome(),
    );
  }
}

class CharsetHome extends StatefulWidget {
  const CharsetHome({super.key});

  @override
  State<CharsetHome> createState() => _CharsetHomeState();
}

class _CharsetHomeState extends State<CharsetHome> {
  final _controller = TextEditingController(text: 'Hello, charset 世界');
  Future<DecodingResult>? _decodeFuture;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _detect() {
    final bytes = Uint8List.fromList(utf8.encode(_controller.text));
    setState(() {
      _decodeFuture = FlutterChardet.autoDecode(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_chardet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Text',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _detect,
              icon: const Icon(Icons.search),
              label: const Text('Detect'),
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<DecodingResult>(
            future: _decodeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return SelectableText(snapshot.error.toString());
              }
              final result = snapshot.requireData;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Charset: ${result.charset}'),
                  Text('Confidence: ${result.confidence.toStringAsFixed(3)}'),
                  if (result.language != null)
                    Text('Language: ${result.language}'),
                  const SizedBox(height: 12),
                  SelectableText(result.text),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
