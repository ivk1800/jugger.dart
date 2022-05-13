import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../errors_glossary.dart';
import '../generator/visitors.dart';
import 'utils.dart';

extension DartTypeExt on DartType {
  /// Whether this type is a [Provider].
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

  /// Returns the only generic type, if not one throws an error.
  /// Type is means:
  /// ```
  /// Provider<
  /// String // <---
  /// >
  /// ```
  DartType get getSingleTypeArgument {
    final InterfaceType interfaceType = this as InterfaceType;
    check(
      interfaceType.typeArguments.length == 1,
      () => buildUnexpectedErrorMessage(
        message: 'interfaceType.typeArguments must be 1',
      ),
    );

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

  String getName() {
    return getDisplayString(withNullability: false);
  }

  /// Returns true if it has one injected constructor, otherwise an error will
  /// be thrown.
  bool hasInjectedConstructor() {
    checkUnsupportedType();
    return getInjectedConstructorOrNull() != null;
  }

  void checkUnsupportedType() {
    check(
      this is InterfaceType,
      () => buildErrorMessage(
        error: JuggerErrorId.type_not_supported,
        message: 'Type $this not supported.',
      ),
    );

    check(
      nullabilitySuffix == NullabilitySuffix.none,
      () => buildErrorMessage(
        error: JuggerErrorId.type_not_supported,
        message: 'Type $this not supported.',
      ),
    );
  }
}
