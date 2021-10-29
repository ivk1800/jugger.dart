import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('bind', () {
    test('bind from another module', () async {
      _checkGenerateCode('bind/bind_from_another_module');
    });
  });

  group('non lazy', () {
    test('simple', () async {
      _checkGenerateCode('non_lazy/non_lazy_simple');
    });

    test('without non lazy', () async {
      _checkGenerateCode('non_lazy/non_lazy_without_non_lazy');
    });
  });
}

Future<void> _checkGenerateCode(String fileName) async {
  final File testContentFile =
      File('${Directory.current.path}/assets/$fileName.txt');
  final File buildContentFile =
      File('${Directory.current.path}/lib/$fileName.jugger.dart');

  assert(testContentFile.existsSync(),
      'test file is missing, ${testContentFile.path}');
  assert(buildContentFile.existsSync(),
      'build file is missing, ${buildContentFile.path}');

  final String testContent = await testContentFile.readAsString();

  final String buildContent = await buildContentFile.readAsString();

  expect(buildContent, testContent);
}
