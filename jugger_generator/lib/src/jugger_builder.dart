// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:build/build.dart';
import 'package:jugger_generator/src/component_builder_delegate.dart';

import 'global_config.dart';

class JuggerBuilder extends Builder {
  JuggerBuilder({required this.options});

  final BuilderOptions options;

  @override
  Future<void> build(BuildStep buildStep) async {
    final GlobalConfig globalConfig = GlobalConfig(
      ignoreInterfacePrefixInComponentName: options
              .config['ignore_interface_prefix_in_component_name'] as bool? ??
          false,
      checkUnusedProviders:
          options.config['check_unused_providers'] as bool? ?? false,
    );
    final ComponentBuilderDelegate delegate = ComponentBuilderDelegate(
      globalConfig: globalConfig,
    );

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
