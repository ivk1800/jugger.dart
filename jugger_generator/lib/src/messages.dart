import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'utils.dart';

String providerNotAllowed(DartType type) {
  return 'found registered dependency of provider [${type.getName()}]';
}

String multipleQualifiersNotAllowed(Element element) {
  return 'multiple qualifiers not allowed [${element.enclosingElement?.name}.${element.name}]';
}

String foundUnusedGeneratedProviders(Iterable<String> variables) {
  return 'found unused generated providers: ${variables.join(', ')}';
}
