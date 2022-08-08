import 'dart:io';

import 'package:path/path.dart';

Future<void> main() async {
  const List<String> ignored = <String>[
    'build_config/custom_line_length',
    'assets/build_config/remove_interface_prefix',
    'generics/provide_type_with_different_generic',
    'build_config/not_remove_interface_prefix',
  ];

  final String rootPath = "${Directory.current.path}/../..";
  final Directory testAssetsDirectory = Directory("$rootPath/tests/assets");
  final Directory libDirectory = Directory("$rootPath/tests/lib");

  final List<String> files = testAssetsDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .map((File e) => e.path.substring(testAssetsDirectory.path.length + 1))
      .map(withoutExtension)
      .where((String path) => !ignored.contains(path))
      .toList(growable: false);

  for (final String filePath in files) {
    final File generatedCodeFile =
        File("${libDirectory.path}/$filePath.jugger.dart");
    if (generatedCodeFile.existsSync()) {
      final File resultFile = File("${testAssetsDirectory.path}/$filePath.txt");
      assert(resultFile.existsSync(), resultFile.path);

      generatedCodeFile.copySync(resultFile.path);
      // ignore: avoid_print
      print('sync: ${resultFile.path}');
    }
  }
}
