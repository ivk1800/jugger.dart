import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:jugger_generator/src/builder/jugger_builder.dart';

Future<String> readAssetFile(String fileName) async {
  final File resultContentFile =
      File('${Directory.current.path}/assets/$fileName.txt');

  assert(
    resultContentFile.existsSync(),
    'file is missing, ${resultContentFile.path}',
  );

  return resultContentFile.readAsString();
}

Future<void> checkBuilderOfFile(
  String fileName, [
  BuilderOptions options = BuilderOptions.empty,
]) async {
  final File resultContentFile =
      File('${Directory.current.path}/assets/$fileName.txt');
  final File codeContentFile =
      File('${Directory.current.path}/lib/$fileName.dart');

  assert(
    resultContentFile.existsSync(),
    'result file is missing, ${resultContentFile.path}',
  );
  assert(
    codeContentFile.existsSync(),
    'code file is missing, ${codeContentFile.path}',
  );

  final String resultContent = await resultContentFile.readAsString();

  final String codeContent = await codeContentFile.readAsString();

  await checkBuilderContent(
    fileName: fileName,
    codeContent: codeContent,
    resultContent: resultContent,
    options: options,
  );
}

Future<void> checkBuilderContent({
  required String fileName,
  required String resultContent,
  required String codeContent,
  void Function(Object error)? onError,
  BuilderOptions options = BuilderOptions.empty,
}) async {
  try {
    await testBuilder(
      JuggerBuilder(
        options: options,
      ),
      <String, String>{'tests|lib/$fileName.dart': codeContent},
      outputs: <String, Object>{
        'tests|lib/$fileName.jugger.dart': resultContent,
      },
      reader: await PackageAssetReader.currentIsolate(),
    );
  } catch (e) {
    if (onError != null) {
      onError.call(e);
    } else {
      rethrow;
    }
  }
}

Future<void> checkBuilderResult({
  required String mainContent,
  void Function(Object error)? onError,
  FutureOr<String> Function()? resultContent,
  Map<String, String> assets = const <String, String>{},
  BuilderOptions options = BuilderOptions.empty,
}) async {
  const String fileName = 'test';
  final String content =
      resultContent != null ? await resultContent.call() : '';
  try {
    await testBuilder(
      JuggerBuilder(options: options),
      <String, String>{
        'tests|lib/$fileName.dart': mainContent,
        ...assets.map(
          (String key, String value) {
            return MapEntry<String, String>('tests|lib/$key', value);
          },
        ),
      },
      outputs: <String, Object>{
        'tests|lib/$fileName.jugger.dart': content,
      },
      reader: await PackageAssetReader.currentIsolate(),
    );
  } catch (e) {
    if (onError == null) {
      rethrow;
    } else {
      onError.call(e);
    }
  }
}
