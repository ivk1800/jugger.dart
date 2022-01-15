import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:jugger_generator/src/utils.dart';

String providerNotFound(
  DartType type,
  String? qualifier,
) {
  return 'Provider for (${type.getName()}${qualifier != null ? ', qualifier: $qualifier' : ''}) not found';
}

String injectedConstructorNotFound(ClassElement element) {
  return 'not found injected constructor for ${element.name}';
}

String bindWrongType(MethodElement method) {
  return '${method.name} bind wrong type ${method.returnType}';
}
