import 'package:code_builder/code_builder.dart';

class ComponentResult {
  ComponentResult({
    required this.componentClass,
    required this.multibindingsProviderClasses,
    required this.hasDisposables,
    required this.componentBuilder,
  });

  final Class componentClass;

  final Class? componentBuilder;

  final List<Class> multibindingsProviderClasses;

  final bool hasDisposables;
}
