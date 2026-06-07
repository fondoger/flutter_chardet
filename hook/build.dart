import 'dart:io';

import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final packageRootPath = input.packageRoot.toFilePath();
    final packageRootPathWithSeparator =
        packageRootPath.endsWith(Platform.pathSeparator)
        ? packageRootPath
        : '$packageRootPath${Platform.pathSeparator}';
    final uchardetSourceRoot = input.packageRoot.resolve(
      'third_party/uchardet/src/',
    );
    final uchardetSources =
        Directory.fromUri(uchardetSourceRoot)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.cpp'))
            .map(
              (file) =>
                  file.path.substring(packageRootPathWithSeparator.length),
            )
            .toList()
          ..sort();

    final cbuilder = CBuilder.library(
      name: packageName,
      assetName: '${packageName}_bindings_generated.dart',
      sources: ['src/$packageName.cc', ...uchardetSources],
      includes: ['src', 'third_party/uchardet/src'],
      language: .cpp,
      std: 'c++11',
    );
    await cbuilder.run(input: input, output: output);
  });
}
