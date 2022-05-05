import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:jugger/jugger.dart';
import 'package:jugger_generator/src/errors_glossary.dart';
import 'package:jugger_generator/src/utils.dart';

import 'tag.dart';

String buildErrorMessage({
  required JuggerErrorId error,
  required String message,
}) =>
    '${error.name}:\n$message\nExplanation of Error: ${error.toLink()}';

String providerNotFound(
  DartType type,
  Tag? tag,
) {
  return 'Provider for (${type.getName()}${tag != null ? ', qualifier: ${tag.originalId}' : ''}) not found';
}

String notProvided(DartType type, Tag? tag) {
  return '[${type.getName()}, qualifier: ${tag?.originalId}] not provided';
}

String injectedConstructorNotFound(ClassElement element) {
  return 'not found injected constructor for ${element.name}';
}

String providerNotAllowed(DartType type) {
  return 'found registered dependency of provider [${type.getName()}]';
}

String bindWrongType(MethodElement method) {
  return '${method.name} bind wrong type ${method.returnType}';
}

String dependencyMustBeAbstract(DartType type) {
  return 'dependency must be abstract [${type.getName()}]';
}

String multipleQualifiersNotAllowed(Element element) {
  return 'multiple qualifiers not allowed [${element.enclosingElement?.name}.${element.name}]';
}

String moduleMustBeAbstract(ClassElement moduleClass) {
  return 'module must be abstract [${moduleClass.thisType.getName()}] ${moduleClass.library.identifier}';
}

String foundUnusedGeneratedProviders(Iterable<String> variables) {
  return 'found unused generated providers: ${variables.join(', ')}';
}

String typeNotSupported(DartType type) {
  return 'type [$type] not supported';
}

String repeatedModules(DartType type) {
  return 'repeated modules [$type] not allowed';
}

String publicComponent(ClassElement element) {
  return 'Component [$element] must be public';
}

String publicModule(ClassElement element) {
  return 'Module [$element] must be public';
}

String moduleAnnotationRequired(ClassElement element) {
  return 'class [${element.name}] ${element.library.identifier} must be annotated as ${module.runtimeType}';
}
