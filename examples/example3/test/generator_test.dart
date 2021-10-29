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
  final String testContent =
      await File('${Directory.current.path}/assets/$fileName.txt')
          .readAsString();

  final String buildContent =
      await File('${Directory.current.path}/lib/bind/$fileName.jugger.dart')
          .readAsString();

  expect(buildContent, testContent);
}
