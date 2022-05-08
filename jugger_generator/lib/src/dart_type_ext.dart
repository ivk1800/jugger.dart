import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import 'errors_glossary.dart';
import 'messages.dart';
import 'utils.dart';
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
    final List<ConstructorElement> injectedConstructors =
        element!.getInjectedConstructors();
    check(
      injectedConstructors.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.ambiguity_of_injected_constructor,
        message:
            'Class ${element?.name} has more than one injected constructor or no injected constructor.',
      ),
    );
    return injectedConstructors.first;
  }

  ConstructorElement? getInjectedConstructorOrNull() {
    checkUnsupportedType();

    final List<ConstructorElement> injectedConstructors =
        element!.getInjectedConstructors();
    check(
      injectedConstructors.length <= 1,
      () => 'required single or zero injected constructor',
    );
    return injectedConstructors.firstOrNull;
  }
}
