import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('bind', () {
    test('bind from another module', () async {
      await _checkGenerateCode('bind/bind_from_another_module');
    });

    test('bind from module', () async {
      await _checkGenerateCode('bind/bind_from_module');
    });
  });

  group('non lazy', () {
    test('simple', () async {
      await _checkGenerateCode('non_lazy/non_lazy_simple');
    });

    test('without non lazy', () async {
      await _checkGenerateCode('non_lazy/non_lazy_without_non_lazy');
    });
  });

  group('provide', () {
    test('from component params', () async {
      await _checkGenerateCode('provide/provide_from_component_params');
    });

    test('from injected constructor', () async {
      await _checkGenerateCode('provide/provide_from_injected_constructor');
    });

    test('from module', () async {
      await _checkGenerateCode('provide/provide_from_module');
    });
  });

  group('component getter', () {
    test('simple', () async {
      await _checkGenerateCode('getter/simple_getter');
    });
    test('from another component', () async {
      await _checkGenerateCode('getter/getter_from_another_component');
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
