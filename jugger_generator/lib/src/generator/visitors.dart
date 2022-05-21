import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart' as j;

import '../errors_glossary.dart';
import '../utils/dart_type_ext.dart';
import '../utils/utils.dart';
import 'wrappers.dart';

class _InjectedMembersVisitor extends RecursiveElementVisitor<dynamic> {
  final List<InjectedMember> members = <InjectedMember>[];

  @override
  dynamic visitFieldElement(FieldElement element) {
    final List<Annotation> annotations = getAnnotations(element);
    if (annotations
        .any((Annotation annotation) => annotation is InjectAnnotation)) {
      check(
        element.isPublic && !element.isStatic && !element.isAbstract,
        () => 'Field ${element.name} must be only public.',
      );
      _add(element);
    }

    return null;
  }

  @override
  dynamic visitConstructorElement(ConstructorElement element) {
    final List<InterfaceType> allSupertypes =
        element.enclosingElement.allSupertypes;

    for (final InterfaceType interfaceType in allSupertypes) {
      final Element element = interfaceType.element;
      if (isFlutterCore(element) || isCore(element)) {
        continue;
      }

      final List<InjectedMember> members = element.getInjectedMembers();

      _addAll(members.map((InjectedMember m) => m.element).toList());
    }
    return null;
  }

  void _add(Element element) {
    // ignore: avoid_as
    members.add(InjectedMember(element as FieldElement));
  }

  void _addAll(List<Element> elements) {
    elements.forEach(_add);
  }
}

class _ProvidesVisitor extends RecursiveElementVisitor<dynamic> {
  final List<Method> methods = <Method>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    final Element moduleElement = element.enclosingElement;
    element.returnType.checkUnsupportedType();

    check(
      element.isAbstract || element.isStatic,
      () => buildErrorMessage(
        error: JuggerErrorId.unsupported_method_type,
        message:
            'Method ${moduleElement.name}.${element.name} must be abstract or static.',
      ),
    );

    check(
      !element.isPrivate,
      () => buildErrorMessage(
        error: JuggerErrorId.private_method_of_module,
        message:
            'Method ${moduleElement.name}.${element.name} can not be private.',
      ),
    );

    final ProvideAnnotation? provideAnnotation = getProvideAnnotation(element);
    if (element.isStatic) {
      check(
        provideAnnotation != null,
        () => buildErrorMessage(
          error: JuggerErrorId.missing_provides_annotation,
          message:
              'Found static method ${moduleElement.name}.${element.name}, but is not annotated with @${j.provides.runtimeType}.',
        ),
      );
    }

    final BindAnnotation? bindAnnotation = getBindAnnotation(element);
    if (element.isAbstract) {
      check(
        bindAnnotation != null,
        () => buildErrorMessage(
          error: JuggerErrorId.missing_bind_annotation,
          message:
              'Found abstract method ${moduleElement.name}.${element.name}, but is not annotated with @${j.binds.runtimeType}.',
        ),
      );
      check(
        element.parameters.length == 1,
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_bind_method,
          message:
              'Method ${moduleElement.name}.${element.name} annotated with ${j.binds.runtimeType} must have one parameter.',
        ),
      );

      final DartType parameterType = element.parameters.first.type;
      parameterType.checkUnsupportedType();
      final Element? typeElement = parameterType.element;

      check(
        typeElement is ClassElement,
        () => buildUnexpectedErrorMessage(
          message: 'Supported only class element.',
        ),
      );

      final bool isSupertype = (typeElement as ClassElement).allSupertypes.any(
          (InterfaceType interfaceType) => interfaceType == element.returnType);

      check(
        isSupertype,
        () => buildErrorMessage(
          error: JuggerErrorId.bind_wrong_type,
          message:
              'Method ${moduleElement.name}.${element.name} parameter type must be assignable to the return type.',
        ),
      );
    }

    check(
      !(bindAnnotation != null && provideAnnotation != null),
      () => buildErrorMessage(
        error: JuggerErrorId.ambiguity_of_provide_method,
        message:
            'Method [${moduleElement.name}.${element.name}] can not be annotated together with @${j.provides.runtimeType} and @${j.binds.runtimeType}',
      ),
    );

    methods.add(Method(element));
    return null;
  }
}

class _ComponentsVisitor extends RecursiveElementVisitor<dynamic> {
  List<Component> components = <Component>[];

  @override
  dynamic visitClassElement(ClassElement element) {
    final ComponentAnnotation? component = getComponentAnnotation(element);

    if (component != null) {
      for (final InterfaceType type in element.allSupertypes) {
        if (type.isDartCoreObject) {
          continue;
        }
        check(
          type.element.isAbstract,
          () => buildErrorMessage(
            error: JuggerErrorId.invalid_component,
            message:
                'Component ${element.name} should only have abstract classes as ancestor.',
          ),
        );
      }

      check(
        element.isPublic,
        () => buildErrorMessage(
          error: JuggerErrorId.public_component,
          message: 'Component ${element.name} must be public.',
        ),
      );
      check(
        element.isAbstract,
        () => buildErrorMessage(
          error: JuggerErrorId.abstract_component,
          message: 'Component ${element.name} must be abstract.',
        ),
      );

      components.add(
        Component.fromElement(element, component),
      );
    }
    return null;
  }
}

class _InjectedConstructorsVisitor extends RecursiveElementVisitor<dynamic> {
  final List<ConstructorElement> injectedConstructors = <ConstructorElement>[];

  @override
  dynamic visitConstructorElement(ConstructorElement element) {
    if (element.hasAnnotatedAsInject()) {
      injectedConstructors.add(element);
    }
    return null;
  }
}

class _InjectedMethodsVisitor extends RecursiveElementVisitor<dynamic> {
  final Set<MethodElement> methods = <MethodElement>{};

  @override
  dynamic visitMethodElement(MethodElement element) {
    final List<Annotation> annotations = getAnnotations(element);

    if (annotations
        .any((Annotation annotation) => annotation is InjectAnnotation)) {
      if (!methods.any((MethodElement collectedMethod) =>
          collectedMethod.name == element.name)) {
        check(
          element.isPublic,
          () => buildErrorMessage(
            error: JuggerErrorId.invalid_injected_method,
            message: 'Injected method ${element.name} must be public.',
          ),
        );
        check(
          !element.isStatic,
          () => buildErrorMessage(
            error: JuggerErrorId.invalid_injected_method,
            message: 'Injected method ${element.name} can not be static.',
          ),
        );
        check(
          !element.isAbstract,
          () => buildErrorMessage(
            error: JuggerErrorId.invalid_injected_method,
            message: 'Injected method ${element.name} can not be abstract.',
          ),
        );
        methods.add(element);
      }
    }

    return null;
  }

  @override
  dynamic visitConstructorElement(ConstructorElement element) {
    final List<InterfaceType> allSupertypes =
        element.enclosingElement.allSupertypes;

    for (final InterfaceType interfaceType in allSupertypes) {
      final Element element = interfaceType.element;
      if (isFlutterCore(element) || isCore(element)) {
        continue;
      }

      element.visitChildren(this);
    }
    return null;
  }
}

class _ComponentBuildersVisitor extends RecursiveElementVisitor<dynamic> {
  List<ComponentBuilder> componentBuilders = <ComponentBuilder>[];

  @override
  dynamic visitClassElement(ClassElement element) {
    final ComponentBuilderAnnotation? annotation =
        getComponentBuilderAnnotation(element);

    if (annotation != null) {
      check(
        element.isPublic,
        () => buildErrorMessage(
          error: JuggerErrorId.public_component_builder,
          message: 'Component builder ${element.name} must be public.',
        ),
      );
      final List<MethodElement> methods = element.getComponentBuilderMethods();

      final Set<DartType> argumentsTypes = <DartType>{};

      for (int i = 0; i < methods.length; i++) {
        final MethodElement methodElement = methods[i];
        check(
          methodElement.isPublic,
          () => buildErrorMessage(
            error: JuggerErrorId.component_builder_private_method,
            message: 'Method ${methodElement.name} must be public.',
          ),
        );

        if (methodElement.name == 'build') {
          check(
            methodElement.parameters.isEmpty,
            () => buildErrorMessage(
              error: JuggerErrorId.wrong_arguments_of_build_method,
              message: 'Build method should not contain arguments.',
            ),
          );
        } else {
          check(
            methodElement.returnType == element.thisType,
            () => buildErrorMessage(
              error: JuggerErrorId.component_builder_invalid_method_type,
              message: 'Invalid type of method ${methodElement.name}. '
                  'Expected ${element.thisType}.',
            ),
          );
          check(
            methodElement.parameters.length == 1,
            () => buildErrorMessage(
              error: JuggerErrorId.component_builder_invalid_method_parameters,
              message:
                  'Method ${methodElement.name} should have only one parameter.',
            ),
          );
          final DartType parameterType = methodElement.parameters.first.type;
          check(
            argumentsTypes.add(parameterType),
            () => buildErrorMessage(
              error:
                  JuggerErrorId.component_builder_type_provided_multiple_times,
              message:
                  'Type $parameterType provided multiple times in component builder ${element.name}',
            ),
          );
        }
      }

      late final MethodElement buildMethod;
      final MethodElement? buildMethodNullable =
          methods.firstWhereOrNull((MethodElement m) {
        return m.name == 'build';
      });
      check(
        buildMethodNullable != null,
        () => buildErrorMessage(
          error: JuggerErrorId.missing_build_method,
          message:
              'Missing required build method of ${createClassNameWithPath(element)}',
        ),
      );
      buildMethod = buildMethodNullable!;

      final ComponentAnnotation? componentAnnotation =
          getComponentAnnotation(buildMethod.returnType.element!);

      final Iterable<MethodElement> externalDependenciesMethods =
          methods.where((MethodElement me) => me.name != buildMethodName);
      for (final DependencyAnnotation dep
          in componentAnnotation!.dependencies) {
        final bool dependencyProvided =
            externalDependenciesMethods.any((MethodElement me) {
          return me.parameters[0].type.element == dep.element;
        });

        check(
          dependencyProvided,
          () => buildErrorMessage(
            error: JuggerErrorId.missing_component_dependency,
            message: 'Dependency (${dep.element.name}) not provided.',
          ),
        );
      }

      for (final MethodElement element in externalDependenciesMethods) {
        element.parameters.first.type.checkUnsupportedType();
      }

      componentBuilders.add(ComponentBuilder(
          element: element,
          methods: methods,
          // ignore: avoid_as
          componentClass: buildMethod.returnType.element as ClassElement));
    }

    return null;
  }

  static const String buildMethodName = 'build';
}

class _ComponentBuilderMethodsVisitor extends RecursiveElementVisitor<dynamic> {
  final List<MethodElement> _methods = <MethodElement>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    if (element.name == 'build') {
      final ComponentAnnotation? componentAnnotation =
          getComponentAnnotation(element.returnType.element!);
      check(
        componentAnnotation != null,
        () => buildErrorMessage(
          error: JuggerErrorId.wrong_type_of_build_method,
          message:
              'build method of ${element.enclosingElement.name} return wrong type.',
        ),
      );
    }
    _methods.add(element);
    return null;
  }
}

class _MethodsVisitor extends GeneralizingElementVisitor<dynamic> {
  final List<MethodElement> _methods = <MethodElement>[];

  @override
  dynamic visitElement(Element element) {
    if (element is ConstructorElement) {
      final List<InterfaceType> allSupertypes =
          element.enclosingElement.allSupertypes;

      for (final InterfaceType interfaceType in allSupertypes) {
        final Element interfaceElement = interfaceType.element;
        if (isFlutterCore(interfaceElement) || isCore(interfaceElement)) {
          return super.visitElement(element);
        }

        return super.visitElement(interfaceElement);
      }
    }
    return super.visitElement(element);
  }

  @override
  dynamic visitMethodElement(MethodElement element) {
    if (!_methods.any((MethodElement collectedMethod) =>
        collectedMethod.name == element.name)) {
      _methods.add(element);
    }
    return super.visitMethodElement(element);
  }
}

class _PropertiesVisitor extends GeneralizingElementVisitor<dynamic> {
  final List<PropertyAccessorElement> _properties = <PropertyAccessorElement>[];

  @override
  dynamic visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!_properties.any((PropertyAccessorElement collectedMethod) =>
        collectedMethod.name == element.name)) {
      _properties.add(element);
    }
    return super.visitPropertyAccessorElement(element);
  }

  @override
  dynamic visitElement(Element element) {
    if (element is ConstructorElement) {
      final List<InterfaceType> allSupertypes =
          element.enclosingElement.allSupertypes;

      for (final InterfaceType interfaceType in allSupertypes) {
        final Element interfaceElement = interfaceType.element;
        if (isFlutterCore(interfaceElement) || isCore(interfaceElement)) {
          return super.visitElement(element);
        }

        return super.visitElement(interfaceElement);
      }
    }
    return super.visitElement(element);
  }
}

extension VisitorExt on Element {
  /// Returns all injected fields of module and validate them. The client must
  /// check that the element is a class.
  List<InjectedMember> getInjectedMembers() {
    final _InjectedMembersVisitor visitor = _InjectedMembersVisitor();
    visitChildren(visitor);
    return visitor.members;
  }

  /// Returns all methods of module and validate them. The client must
  /// check that the element is a module.
  List<Method> getProvides() {
    final _ProvidesVisitor visitor = _ProvidesVisitor();
    visitChildren(visitor);
    return visitor.methods;
  }

  /// Returns all methods of module for inject and validate them. The client
  /// must check that the element is a module.
  List<MemberInjectorMethod> getMemberInjectors() {
    final List<MemberInjectorMethod> methods = getMethods()
        .where((element) => element.returnType.getName() == 'void')
        .map((e) => MemberInjectorMethod(e))
        .toList(growable: false);

    for (final MemberInjectorMethod injectedMethod in methods) {
      MethodElement method = injectedMethod.element;
      check(
        method.parameters.length == 1,
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_injectable_method,
          message: 'Injected method ${method.name} must have one parameter.',
        ),
      );
    }

    return methods;
  }

  /// Returns all components of library and validate them. The client must check
  /// that the element is a LibraryElement.
  List<Component> getComponents() {
    final _ComponentsVisitor visitor = _ComponentsVisitor();
    visitChildren(visitor);
    return visitor.components;
  }

  /// Returns all injected methods of class and validate them. Collect unique
  /// methods without repeating. The client must check that the element is a
  /// class.
  Set<MethodElement> getInjectedMethods() {
    final _InjectedMethodsVisitor visitor = _InjectedMethodsVisitor();
    visitChildren(visitor);
    return visitor.methods;
  }

  /// Returns all component builders of library and validate them. The client
  /// must check that the element is a LibraryElement.
  List<ComponentBuilder> getComponentBuilders() {
    final _ComponentBuildersVisitor visitor = _ComponentBuildersVisitor();
    visitChildren(visitor);
    return visitor.componentBuilders;
  }

  /// Returns all injected constructors of class and validate them. The client
  /// must check that the element is a class.
  List<ConstructorElement> getInjectedConstructors() {
    final _InjectedConstructorsVisitor visitor = _InjectedConstructorsVisitor();
    visitChildren(visitor);
    return visitor.injectedConstructors;
  }

  /// Returns all methods of component builder and validate them. The client
  /// must check that the element is a component builder.
  List<MethodElement> getComponentBuilderMethods() {
    final _ComponentBuilderMethodsVisitor visitor =
        _ComponentBuilderMethodsVisitor();
    visitChildren(visitor);
    return visitor._methods;
  }

  /// Returns all methods of the component and validate them, except for
  /// the void methods for the injection. The client must check that the element
  /// is a component.
  List<MethodElement> getComponentProvideMethods() {
    final List<MethodElement> methods = getMethods()
        // skip methods that deal with injection
        .where((element) => element.returnType.getName() != 'void')
        .toList(growable: false);

    for (final MethodElement method in methods) {
      check(
        method.parameters.isEmpty,
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_method_of_component,
          message:
              'Method ${method.name} of component must have zero parameters.',
        ),
      );

      check(
        method.isAbstract,
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_method_of_component,
          message: 'Method ${method.name} of component must be abstract.',
        ),
      );

      check(
        method.isPublic,
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_method_of_component,
          message: 'Method ${method.name} of component must be public.',
        ),
      );
    }
    return methods;
  }

  /// Returns all properties of the component and validate them. The
  /// client must check that the element is a component.
  List<PropertyAccessorElement> getProvideProperties() {
    final List<PropertyAccessorElement> properties = getProperties();
    for (final PropertyAccessorElement property in properties) {
      check(property.isGetter, () => 'null');
    }
    return properties;
  }

  /// Returns all methods of the component.
  List<MethodElement> getMethods() {
    final _MethodsVisitor visitor = _MethodsVisitor();
    visitChildren(visitor);
    return visitor._methods;
  }

  /// Returns all properties of the component.
  List<PropertyAccessorElement> getProperties() {
    final _PropertiesVisitor visitor = _PropertiesVisitor();
    visitChildren(visitor);
    return visitor._properties;
  }
}
