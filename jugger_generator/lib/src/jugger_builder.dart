// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:build/build.dart';
import 'package:jugger_generator/src/component_builder_delegate.dart';

class JuggerBuilder extends Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    final ComponentBuilderDelegate delegate = ComponentBuilderDelegate();

    final String outputContents = await delegate.buildOutput(buildStep);
    if (outputContents.trim().isEmpty || _isTestAsset(buildStep.inputId)) {
      return Future<void>.value(null);
    }
    final AssetId outputFile =
        buildStep.inputId.changeExtension('.$outputExtension');

    buildStep.writeAsString(outputFile, outputContents);

    return Future<void>.value(null);
  }

  @override
  Map<String, List<String>> get buildExtensions => <String, List<String>>{
        '.$inputExtension': <String>['.$outputExtension']
      };

  String get inputExtension => 'dart';

  String get outputExtension => 'jugger.dart';

  bool _isTestAsset(AssetId inputId) {
    return inputId.pathSegments.first == 'test';
  }
}
