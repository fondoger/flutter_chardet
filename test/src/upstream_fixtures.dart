import 'dart:io';

final class UpstreamFixture {
  const UpstreamFixture({
    required this.file,
    required this.relativePath,
    required this.expectedLanguage,
    required this.expectedCharset,
  });

  final File file;
  final String relativePath;
  final String expectedLanguage;
  final String expectedCharset;
}

const knownBrokenUpstreamFixtures = {
  'ja:utf-16le': 'Known broken in upstream test/CMakeLists.txt.',
  'ja:utf-16be': 'Known broken in upstream test/CMakeLists.txt.',
  'es:iso-8859-15': 'Known broken in upstream test/CMakeLists.txt.',
  'da:iso-8859-1': 'Known broken in upstream test/CMakeLists.txt.',
  'he:iso-8859-8': 'Known broken in upstream test/CMakeLists.txt.',
  'zh:gb18030':
      'Fails in upstream uchardet-tests at commit 06029ec; GB18030 is candidate #2.',
};

List<UpstreamFixture> upstreamFixtures() {
  final root = Directory('test/upstream');
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => !file.path.endsWith('uchardet-tests.c'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  return files.map((file) {
    final segments = file.path.split(Platform.pathSeparator);
    final fileName = segments.last;
    return UpstreamFixture(
      file: file,
      relativePath: file.path,
      expectedLanguage: segments[segments.length - 2],
      expectedCharset: fileName.split('.').first.toLowerCase(),
    );
  }).toList();
}

String fixtureKey(UpstreamFixture fixture) {
  return '${fixture.expectedLanguage}:${fixture.expectedCharset}';
}
