import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('binds', () {
    test('from another module', () async {
      await _checkGenerateCode('binds/binds_from_another_module');
    });

    test('from module', () async {
      await _checkGenerateCode('binds/binds_from_module');
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

  group('provides', () {
    test('from component params', () async {
      await _checkGenerateCode('provides/provides_from_component_params');
    });

    test('from injected constructor', () async {
      await _checkGenerateCode('provides/provides_from_injected_constructor');
    });

    test('from module', () async {
      await _checkGenerateCode('provides/provides_from_module');
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

  group('qualifier', () {
    test('custom qualifier', () async {
      await _checkGenerateCode('qualifier/custom/custom_qualifier');
    });
    test('multiple custom qualifiers', () async {
      await _checkGenerateCode('qualifier/custom/multiple_custom_qualifiers');
    });
    test('multiple named qualifiers', () async {
      await _checkGenerateCode('qualifier/named/multiple_named_qualifiers');
    });
    test('named qualifier and default', () async {
      await _checkGenerateCode('qualifier/named/named_qualifier_and_default');
    });
    test('named qualifier provides param', () async {
      await _checkGenerateCode(
          'qualifier/named/named_qualifier_provides_param');
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
