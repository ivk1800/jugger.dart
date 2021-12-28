import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:jugger_generator/src/jugger_builder.dart';

Future<void> checkBuilderOfFile(
  String fileName, [
  BuilderOptions options = BuilderOptions.empty,
]) async {
  final File resultContentFile =
      File('${Directory.current.path}/assets/$fileName.txt');
  final File codeContentFile =
      File('${Directory.current.path}/lib/$fileName.dart');

  assert(resultContentFile.existsSync(),
      'result file is missing, ${resultContentFile.path}');
  assert(codeContentFile.existsSync(),
      'code file is missing, ${codeContentFile.path}');

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
      <String, String>{'example|lib/$fileName.dart': codeContent},
      outputs: <String, Object>{
        'example|lib/$fileName.jugger.dart': resultContent,
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

Future<void> checkBuilderError({
  required String codeContent,
  required void Function(Object error) onError,
  BuilderOptions options = BuilderOptions.empty,
}) async {
  const String fileName = 'test.dart';
  const String resultContent = '';
  try {
    await testBuilder(
      JuggerBuilder(options: options),
      <String, String>{'example|lib/$fileName.dart': codeContent},
      outputs: <String, Object>{
        'example|lib/$fileName.jugger.dart': resultContent,
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
