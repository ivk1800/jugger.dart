import 'package:code_builder/code_builder.dart';

class ComponentResult {
  ComponentResult({
    required this.componentClasses,
    required this.multibindingsProviderClasses,
    required this.hasDisposables,
    required this.componentBuilders,
  });

  final List<Class> componentClasses;

  final List<Class> componentBuilders;

  final List<Class> multibindingsProviderClasses;

  final bool hasDisposables;
}
