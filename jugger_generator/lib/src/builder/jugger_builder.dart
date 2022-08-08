// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:build/build.dart';

import '../generator/asset_builder.dart';
import 'global_config.dart';

class JuggerBuilder extends Builder {
  JuggerBuilder({required this.options});

  final BuilderOptions options;

  late final GlobalConfig globalConfig = GlobalConfig(
    removeInterfacePrefixFromComponentName: options
            .config['remove_interface_prefix_from_component_name'] as bool? ??
        true,
    checkUnusedProviders:
        options.config['check_unused_providers'] as bool? ?? true,
    lineLength: options.config['generated_file_line_length'] as int? ?? 80,
  );

  @override
  Future<void> build(BuildStep buildStep) async {
    if (_isTestAsset(buildStep.inputId)) {
      return Future<void>.value();
    }

    final AssetBuilder assetBuilder = AssetBuilder(
      globalConfig: globalConfig,
    );

    final String? outputContents = await assetBuilder.buildOutput(buildStep);
    if (outputContents == null || outputContents.trim().isEmpty) {
      return Future<void>.value();
    }
    final AssetId outputFile =
        buildStep.inputId.changeExtension('.$outputExtension');

    await buildStep.writeAsString(outputFile, outputContents);

    return Future<void>.value();
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
