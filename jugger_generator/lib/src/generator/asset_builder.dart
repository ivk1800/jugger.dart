import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart' show InvalidGenerationSourceError;

import '../builder/global_config.dart';
import '../errors_glossary.dart';
import '../jugger_error.dart';
import 'asset_context.dart';
import 'check_unused_providers.dart';
import 'component_builder_delegate.dart';
import 'component_circular_dependency_detector.dart';
import 'component_result.dart';
import 'visitors.dart';
import 'wrappers.dart' as j;

/// Delegate to generate the jugger components within one asset.
class AssetBuilder implements AssetContext {
  AssetBuilder({required this.globalConfig});

  final Allocator _allocator = Allocator.simplePrefixing();
  late final DartEmitter _emitter = DartEmitter(
    allocator: _allocator,
    useNullSafetySyntax: true,
  );
  final ComponentCircularDependencyDetector
      _componentCircularDependencyDetector =
      ComponentCircularDependencyDetector();

  bool _isDisposableManagerClassAdded = false;

  static const List<String> ignores = <String>[
    'ignore_for_file: implementation_imports',
    'ignore_for_file: prefer_const_constructors',
    'ignore_for_file: always_specify_types',
    'ignore_for_file: directives_ordering',
    'ignore_for_file: non_constant_identifier_names',
    'ignore_for_file: type=lint',
    'ignore_for_file: unused_field',
  ];

  /// Returns the generated component code, null if there is nothing to generate
  /// for buildStep.
  Future<String?> buildOutput(BuildStep buildStep) async {
    try {
      return await _buildOutputInternal(buildStep);
    } catch (e) {
      if (e is JuggerError) {
        throw InvalidGenerationSourceError(
          'error: ${e.message}',
          element: e.element,
        );
      } else {
        throw UnexpectedJuggerError(
          buildUnexpectedErrorMessage(message: e.toString()),
        );
      }
    }
  }

  Future<String?> _buildOutputInternal(BuildStep buildStep) async {
    final Resolver resolver = buildStep.resolver;

    if (await resolver.isLibrary(buildStep.inputId)) {
      final LibraryElement lib = await buildStep.inputLibrary;

      final List<j.Component> components = lib.getComponents();

      // skip if nothing to generate
      if (components.isEmpty) {
        return null;
      }

      final LibraryBuilder target = LibraryBuilder();

      for (int i = 0; i < components.length; i++) {
        final j.Component component = components[i];

        _handleComponent(
          target: target,
          component: component,
        );
      }

      return _createTargetContext(target);
    }

    return '';
  }

  String _createTargetContext(LibraryBuilder target) {
    final String fileText = target.build().accept(_emitter).toString();

    if (globalConfig.checkUnusedProviders) {
      checkUnusedProviders(fileText);
    }

    final String finalFileText = fileText.isEmpty
        ? ''
        : '${ignores.map((String line) => '// $line').join('\n')}\n$fileText';
    return DartFormatter(
      pageWidth: globalConfig.lineLength,
    ).format(finalFileText);
  }

  void _handleComponent({
    required j.Component component,
    required LibraryBuilder target,
  }) {
    final ComponentBuilderDelegate componentBuilderDelegate =
        ComponentBuilderDelegate(assetContext: this);

    final ComponentResult result = componentBuilderDelegate.generateComponent(
      component: component,
    );
    result.componentClasses.forEach(target.body.add);
    result.componentBuilders.forEach(target.body.add);

    result.multibindingsProviderClasses.forEach(target.body.add);

    if (result.hasDisposables && !_isDisposableManagerClassAdded) {
      target.body.add(
        ComponentBuilderDelegate.buildDisposableManagerClass(allocator),
      );
      _isDisposableManagerClassAdded = true;
    }
  }

  @override
  final GlobalConfig globalConfig;

  @override
  Allocator get allocator => _allocator;

  @override
  DartEmitter get emitter => _emitter;

  @override
  ComponentCircularDependencyDetector get componentCircularDependencyDetector =>
      _componentCircularDependencyDetector;
}
