import 'package:analyzer/dart/element/element.dart';

import 'visitors.dart';

extension ClassElementExt on ClassElement {
  Set<MethodElement> getInjectedMethods() {
    final InjectedMethodsVisitor injectedMethodsVisitor =
        InjectedMethodsVisitor();
    visitChildren(injectedMethodsVisitor);
    return injectedMethodsVisitor.methods;
  }
}
