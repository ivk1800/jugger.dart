import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:jugger_generator/src/utils.dart';

import 'visitors.dart';

extension DartTypeExt on DartType {
  bool get isProvider {
    if (element == null) {
      return false;
    }

    final LibraryElement? library = element!.library;

    if (library == null) {
      return false;
    }

    return library.location!.components.any(
          (String component) => component == 'package:jugger/src/provider.dart',
        ) &&
        element!.name == 'IProvider';
  }

  DartType get providerType {
    final InterfaceType interfaceType = this as InterfaceType;
    assert(interfaceType.typeArguments.length == 1);

    return interfaceType.typeArguments.first;
  }

  ConstructorElement getRequiredInjectedConstructor() {
    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element!.visitChildren(visitor);
    check2(
      visitor.injectedConstructors.length == 1,
      () => 'required single injected constructor',
    );
    return visitor.injectedConstructors.first.element;
  }

  ConstructorElement? getInjectedConstructorOrNull() {
    checkUnsupportedType();

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element!.visitChildren(visitor);
    check2(
      visitor.injectedConstructors.length <= 1,
      () => 'required single or zero injected constructor',
    );
    return visitor.injectedConstructors.firstOrNull?.element;
  }
}
