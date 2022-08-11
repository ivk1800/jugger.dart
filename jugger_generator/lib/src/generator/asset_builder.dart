import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';

import '../builder/global_config.dart';
import '../errors_glossary.dart';
import '../jugger_error.dart';
import 'asset_context.dart';
import 'check_unused_providers.dart';
import 'component_builder_delegate.dart';
import 'component_result.dart';
import 'type_name_registry.dart';
import 'unique_name_registry.dart';
import 'visitors.dart';
import 'wrappers.dart' as j;

/// Delegate to generate the jugger components within one asset.
class AssetBuilder implements AssetContext {
  AssetBuilder({required this.globalConfig});

  late final LibraryElement _lib;
  late final List<j.ComponentBuilder> _componentBuilders;
  final Allocator _allocator = Allocator.simplePrefixing();
  final TypeNameGenerator _typeNameGenerator = TypeNameGenerator();
  final UniqueIdGenerator _uniqueIdGenerator = UniqueIdGenerator();

  bool _isDisposableManagerClassAdded = false;

  static const List<String> ignores = <String>[
    'ignore_for_file: implementation_imports',
    'ignore_for_file: prefer_const_constructors',
    'ignore_for_file: always_specify_types',
    'ignore_for_file: directives_ordering',
    'ignore_for_file: non_constant_identifier_names',
  ];

  /// Returns the generated component code, null if there is nothing to generate
  /// for buildStep.
  Future<String?> buildOutput(BuildStep buildStep) async {
    try {
      return await _buildOutputInternal(buildStep);
    } catch (e) {
      if (e is! JuggerError) {
        throw UnexpectedJuggerError(
          buildUnexpectedErrorMessage(message: e.toString()),
        );
      } else {
        rethrow;
      }
    }
  }

  Future<String?> _buildOutputInternal(BuildStep buildStep) async {
    final Resolver resolver = buildStep.resolver;

    if (await resolver.isLibrary(buildStep.inputId)) {
      final LibraryElement lib = await buildStep.inputLibrary;
      _lib = lib;

      final List<j.Component> components = lib.getComponents();

      // skip if nothing to generate
      if (components.isEmpty) {
        return null;
      }

      final LibraryBuilder target = LibraryBuilder();

      _componentBuilders = lib.getComponentBuilders();

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
    final String fileText =
        target.build().accept(DartEmitter(allocator: _allocator)).toString();

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
    target.body.add(result.componentClass);

    final Class? componentBuilderClass = result.componentBuilder;
    if (componentBuilderClass != null) {
      target.body.add(componentBuilderClass);
    }

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
  TypeNameGenerator get typeNameGenerator => _typeNameGenerator;

  @override
  UniqueIdGenerator get uniqueIdGenerator => _uniqueIdGenerator;

  @override
  LibraryElement get lib => _lib;

  @override
  j.ComponentBuilder? getComponentBuilderOf(DartType type) {
    return _componentBuilders.firstWhereOrNull((j.ComponentBuilder b) {
      return b.componentClass.thisType == type;
    });
  }
}
