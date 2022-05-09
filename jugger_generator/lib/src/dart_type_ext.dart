import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

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

  /// Returns the required injected constructor. This means that it should be
  /// only single and should be validated.
  ConstructorElement getRequiredInjectedConstructor() {
    final List<ConstructorElement> injectedConstructors =
        element!.getInjectedConstructors();

    return _getSingleInjectedConstructor(injectedConstructors);
  }

  /// Returns null if there are no injected constructors, otherwise an injected
  /// constructor if he is single. Performs validation and may throw an error.
  ConstructorElement? getInjectedConstructorOrNull() {
    checkUnsupportedType();

    final List<ConstructorElement> injectedConstructors =
        element!.getInjectedConstructors();

    if (injectedConstructors.isEmpty) {
      return null;
    }

    return _getSingleInjectedConstructor(injectedConstructors);
  }

  /// Returns the injected constructor and validates it. If more than one
  /// constructor throws an error.
  ConstructorElement _getSingleInjectedConstructor(
    List<ConstructorElement> injectedConstructors,
  ) {
    check(
      injectedConstructors.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.ambiguity_of_injected_constructor,
        message:
            'Class ${element?.name} has more than one injected constructor or no injected constructor.',
      ),
    );
    final ConstructorElement constructorElement = injectedConstructors.first;

    late final String constructorLogName =
        '${constructorElement.enclosingElement.name}.${constructorElement.name}';

    check(
      !constructorElement.isPrivate,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_injected_constructor,
        message: 'Constructor $constructorLogName can not be private.',
      ),
    );
    check(
      !constructorElement.isFactory,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_injected_constructor,
        message: 'Factory constructor $constructorLogName not supported.',
      ),
    );
    check(
      constructorElement.name.isEmpty,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_injected_constructor,
        message: 'Named constructor $constructorLogName not supported.',
      ),
    );

    return constructorElement;
  }
}
