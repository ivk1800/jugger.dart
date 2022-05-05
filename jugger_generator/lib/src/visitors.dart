import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart' as j;

import 'classes.dart';
import 'errors_glossary.dart';
import 'jugger_error.dart';
import 'messages.dart';
import 'utils.dart';

class _InjectedMembersVisitor extends RecursiveElementVisitor<dynamic> {
  final List<InjectedMember> members = <InjectedMember>[];

  @override
  dynamic visitFieldElement(FieldElement element) {
    final List<Annotation> annotations = getAnnotations(element);
    if (annotations
        .any((Annotation annotation) => annotation is InjectAnnotation)) {
      // ignore: flutter_style_todos
      //TODO: check another dynamic states
      if (!element.isPublic || element.isStatic) {
        throw JuggerError(
          'field ${element.name} must be only public',
        );
      }
      _add(element);
    }

    return null;
  }

  @override
  dynamic visitConstructorElement(ConstructorElement element) {
    final List<InterfaceType> allSupertypes =
        element.enclosingElement.allSupertypes;

    for (InterfaceType interfaceType in allSupertypes) {
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
    check(
      moduleElement.hasAnnotatedAsModule(),
      () => moduleAnnotationRequired(moduleElement as ClassElement),
    );

    final List<Annotation> annotations = getAnnotations(element);

    if (!element.isAbstract && !element.isStatic) {
      throw JuggerError(
        'provided method must be abstract or static [${moduleElement.name}.${element.name}]',
      );
    }

    if (element.isPrivate) {
      throw JuggerError(
        'provided method can not be private [${moduleElement.name}.${element.name}]',
      );
    }

    if (element.isStatic) {
      check(
        getProvideAnnotation(element) != null,
        () =>
            'provide static method [${moduleElement.name}.${element.name}] must be annotated [${j.provides.runtimeType}]',
      );
    }

    if (element.isAbstract) {
      check(
        getBindAnnotation(element) != null,
        () =>
            'provide abstract method [${moduleElement.name}.${element.name}] must be annotated [${j.binds.runtimeType}]',
      );
      check(
        element.parameters.length == 1,
        () =>
            'method [${moduleElement.name}.${element.name}] annotates [${j.binds.runtimeType}] must have 1 parameter',
      );
      // ignore: flutter_style_todos
      //TODO: check parameter type must be assignable to the return type
    }

    if (getBindAnnotation(element) != null &&
        getProvideAnnotation(element) != null) {
      throw JuggerError(
        'provide method [${moduleElement.name}.${element.name}] can not be annotated together [${j.provides.runtimeType}] and [${j.binds.runtimeType}]',
      );
    }

    methods.add(Method(element, annotations));
    return null;
  }
}

class _InjectedFieldsVisitor extends RecursiveElementVisitor<dynamic> {
  List<MemberInjectorMethod> fields = <MemberInjectorMethod>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    if (element.returnType.getName() != 'void') {
      return null;
    }

    if (element.parameters.length != 1) {
      throw JuggerError(
        'method ${element.name} must have 1 parameter',
      );
    }

    fields.add(MemberInjectorMethod(element));
    return null;
  }
}

class _ComponentsVisitor extends RecursiveElementVisitor<dynamic> {
  List<Component> components = <Component>[];

  @override
  dynamic visitClassElement(ClassElement element) {
    final ComponentAnnotation? component = getComponentAnnotation(element);

    if (component != null) {
      check(element.isPublic, () => publicComponent(element));

      final _InjectedFieldsVisitor fieldsVisitor = _InjectedFieldsVisitor();
      element.visitChildren(fieldsVisitor);
      components.add(
        Component(
            element: element,
            annotations: <Annotation>[component],
            memberInjectors: element.getMemberInjectors()),
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
          !element.isStatic,
          () => 'injected method [${element.name}] can not be static',
        );
        check(
          !element.isAbstract,
          () => 'injected method [${element.name}] can not be abstract',
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

    for (InterfaceType interfaceType in allSupertypes) {
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

      check(
        componentAnnotation != null,
        () => 'build method must return component',
      );

      final Iterable<MethodElement> externalDependenciesMethods =
          methods.where((MethodElement me) => me.name != BuildMethodName);
      for (DependencyAnnotation dep in componentAnnotation!.dependencies) {
        final bool dependencyProvided =
            externalDependenciesMethods.any((MethodElement me) {
          check(
            me.parameters.length == 1,
            () => 'build method (${me.name}) must have 1 parameter',
          );
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

      for (MethodElement element in externalDependenciesMethods) {
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

  static const String BuildMethodName = 'build';
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

class _ProvideMethodsVisitor extends RecursiveElementVisitor<dynamic> {
  final List<MethodElement> _methods = <MethodElement>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    // skip methods that deal with injection
    if (element.returnType.getName() == 'void') {
      return null;
    }

    if (!element.isAbstract) {
      throw JuggerError(
        '${element.name} not abstract',
      );
    }

    _methods.add(element);
    return null;
  }
}

class _ProvidePropertyVisitor extends RecursiveElementVisitor<dynamic> {
  List<PropertyAccessorElement> properties = <PropertyAccessorElement>[];

  @override
  dynamic visitFieldElement(FieldElement element) {
    return null;
  }

  @override
  dynamic visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (element.isGetter) {
      properties.add(element);
    }

    return null;
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
    final _InjectedFieldsVisitor visitor = _InjectedFieldsVisitor();
    visitChildren(visitor);
    return visitor.fields;
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

  /// Returns all methods that the component has and validate them, except for
  /// the void methods for the injection. The client must check that the element
  /// is a component.
  List<MethodElement> getComponentProvideMethods() {
    final _ProvideMethodsVisitor visitor = _ProvideMethodsVisitor();
    visitChildren(visitor);
    return visitor._methods;
  }

  /// Returns all properties that the component has and validate them. The
  /// client must check that the element is a component.
  List<PropertyAccessorElement> getProvideProperties() {
    final _ProvidePropertyVisitor visitor = _ProvidePropertyVisitor();
    visitChildren(visitor);
    return visitor.properties;
  }
}
