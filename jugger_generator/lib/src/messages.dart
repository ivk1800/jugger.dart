import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'errors_glossary.dart';
import 'tag.dart';
import 'utils.dart';

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

String providerNotAllowed(DartType type) {
  return 'found registered dependency of provider [${type.getName()}]';
}

String multipleQualifiersNotAllowed(Element element) {
  return 'multiple qualifiers not allowed [${element.enclosingElement?.name}.${element.name}]';
}

String foundUnusedGeneratedProviders(Iterable<String> variables) {
  return 'found unused generated providers: ${variables.join(', ')}';
}
