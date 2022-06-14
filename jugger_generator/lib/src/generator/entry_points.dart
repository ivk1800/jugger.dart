import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../utils/dart_type_ext.dart';
import 'component_context.dart';
import 'tag.dart';

String? findEntryPointsOf(
  DartType type,
  Tag? tag,
  List<GraphObject> objectsGraph,
  ProviderSource Function(DartType type, Tag? tag) findProvider,
) {
  final Iterable<GraphObject> dependOn =
      objectsGraph.where((GraphObject object) {
    return object.dependencies.any((GraphObject dependency) {
      return dependency.type == type && dependency.tag == tag;
    });
  });
  if (dependOn.isEmpty) {
    return null;
  }

  final List<ProviderSource> providers = dependOn.map((GraphObject object) {
    return findProvider(object.type, object.tag);
  }).toList(growable: false);

  return providers.map((ProviderSource source) {
    if (source is ModuleSource) {
      final ParameterElement? parameter = source.method.element.parameters
          .firstWhereOrNull((ParameterElement element) => element.type == type);
      final StringBuffer messageBuilder = StringBuffer();

      messageBuilder.write(
        '${source.moduleClass.name}.${source.method.element.name}',
      );
      messageBuilder.write('(');
      if (tag != null) {
        messageBuilder.write('@${tag.originalId}');
        messageBuilder.write(' ');
      }
      messageBuilder.write('${parameter?.type.getName()} ${parameter?.name}');
      messageBuilder.write(')');

      return messageBuilder.toString();
    } else if (source is InjectedConstructorSource) {
      final ParameterElement? parameter = source.element.parameters
          .firstWhereOrNull((ParameterElement element) => element.type == type);
      final StringBuffer messageBuilder = StringBuffer();
      messageBuilder.write(source.element.enclosingElement.name);
      messageBuilder.write('(');
      if (tag != null) {
        messageBuilder.write('@${tag.originalId}');
        messageBuilder.write(' ');
      }
      messageBuilder.write(
        '${parameter?.type.getName()} ${parameter?.name}',
      );
      messageBuilder.write(')');

      return messageBuilder.toString();
    }
    return '';
  }).join('\n');
}
