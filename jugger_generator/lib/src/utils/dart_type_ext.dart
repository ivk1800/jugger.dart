import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart' hide FunctionType, RecordType;

import '../errors_glossary.dart';
import '../generator/visitors.dart';
import '../generator/wrappers.dart';
import '../jugger_error.dart';
import 'element_ext.dart';
import 'list_ext.dart';
import 'object_ext.dart';
import 'utils.dart';

extension DartTypeExt on DartType {
  /// Whether this type is a [IProvider] or [ILazy].
  bool get isValueProvider {
    if (element == null) {
      return false;
    }

    final LibraryElement? library = element!.library;

    if (library == null) {
      return false;
    }

    return library.location!.components.any(
          (String component) =>
              component == 'package:jugger/src/provider.dart' ||
              component == 'package:jugger/src/lazy.dart',
        ) &&
        (element!.name == 'IProvider' || element!.name == 'ILazy');
  }

  /// Whether this type is a [ILazy].
  bool get isLazyType {
    if (element == null) {
      return false;
    }

    final LibraryElement? library = element!.library;

    if (library == null) {
      return false;
    }

    return library.location!.components.any(
          (String component) => component == 'package:jugger/src/lazy.dart',
        ) &&
        element!.name == 'ILazy';
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
    checkUnexpected(
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
        _getInjectedConstructorsOfClass(element!);

    return _getSingleInjectedConstructor(injectedConstructors);
  }

  /// Returns null if there are no injected constructors, otherwise an injected
  /// constructor if he is single. Performs validation and may throw an error.
  ConstructorElement? getInjectedConstructorOrNull() {
    checkUnsupportedType();

    final List<ConstructorElement> injectedConstructors =
        _getInjectedConstructorsOfClass(element!);

    if (injectedConstructors.isEmpty) {
      return null;
    }

    return _getSingleInjectedConstructor(injectedConstructors);
  }

  List<ConstructorElement> _getInjectedConstructorsOfClass(Element element) {
    final ClassElement classElement = element.requiredType<ClassElement>();
    if (classElement.isAbstract) {
      return const <ConstructorElement>[];
    }

    return classElement.getInjectedConstructors();
  }

  /// Returns the injected constructor and validates it. If more than one
  /// constructor throws an error.
  ConstructorElement _getSingleInjectedConstructor(
    List<ConstructorElement> injectedConstructors,
  ) {
    if (injectedConstructors.length != 1) {
      final ClassElement classElement = element.requiredType<ClassElement>();
      final String message;
      if (injectedConstructors.isEmpty) {
        if (classElement.isAbstract) {
          message = 'Provider for ${element?.name} not found.';
        } else {
          message =
              'Class ${element?.name} cannot be provided without an @inject '
              'constructor.';
        }
      } else {
        message =
            'Class ${element?.name} may only contain one injected constructor.';
      }

      final JuggerErrorId error;

      if (injectedConstructors.isEmpty) {
        if (classElement.isAbstract) {
          error = JuggerErrorId.missing_provider;
        } else {
          error = JuggerErrorId.missing_injected_constructor;
        }
      } else {
        error = JuggerErrorId.multiple_injected_constructors;
      }

      throw ProviderNotFoundError(
        type: this,
        tag: null,
        message: buildErrorMessage(error: error, message: message),
      );
    }
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

  DisposableAnnotation? getDisposableAnnotation() =>
      getAnnotations(element!).firstInstanceOrNull<DisposableAnnotation>();

  bool isDisposable() =>
      getAnnotations(element!).anyInstance<DisposableAnnotation>();

  bool isScoped() => getAnnotations(element!).anyInstance<ScopeAnnotation>();

  void checkUnsupportedType() {
    check(
      this is InterfaceType ||
          this is RecordType ||
          this is VoidType ||
          this is FunctionType,
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

  ComponentBuilder? resolveComponentBuilder(DartType expectedComponentType) {
    final ComponentBuilder? componentBuilder =
        element?.getComponentBuilderOrNull();

    if (componentBuilder != null) {
      check(
        expectedComponentType == componentBuilder.componentClass.thisType,
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_subcomponent_factory,
          message: 'The ${componentBuilder.element.name} is not suitable for '
              'the ${expectedComponentType.getName()} it is bound to.',
        ),
      );
    }
    return componentBuilder;
  }

  Reference asReference() {
    final Element? e = element;
    checkUnexpected(
      e != null,
      () => 'Unable create Reference, element is null.',
    );
    return e!.asReference();
  }
}
