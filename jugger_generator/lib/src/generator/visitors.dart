import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart' as j;

import '../errors_glossary.dart';
import '../jugger_error.dart';
import '../utils/dart_type_ext.dart';
import '../utils/element_annotation_ext.dart';
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
      if (isCore(element)) {
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

class _ModuleMethodsVisitor extends RecursiveElementVisitor<dynamic>
    with CheckSupportedMemberMixin<dynamic> {
  final List<ModuleMethod> _methods = <ModuleMethod>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    final Element moduleElement = element.enclosingElement;

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

    final ProvideAnnotation? provideAnnotation =
        element.getProvideAnnotationOrNull();
    final BindAnnotation? bindAnnotation = element.getBindAnnotationOrNull();
    final DisposalHandlerAnnotation? disposalHandlerAnnotation =
        element.getDisposalHandlerAnnotationOrNull();

    check(
      !(bindAnnotation != null && provideAnnotation != null),
      () => buildErrorMessage(
        error: JuggerErrorId.ambiguity_of_provide_method,
        message:
            'Method [${moduleElement.name}.${element.name}] can not be annotated together with @${j.provides.runtimeType} and @${j.binds.runtimeType}',
      ),
    );

    if (element.isStatic) {
      if (disposalHandlerAnnotation != null) {
        final String type = element.returnType.getName();
        check(
          type == 'Future<void>' || type == 'void',
          () => buildErrorMessage(
            error: JuggerErrorId.invalid_handler_method,
            message: 'Disposal handler must return type Future<void> or void.',
          ),
        );
        _methods.add(DisposalHandlerMethod.fromMethodElement(element));
        return null;
      }

      element.returnType.checkUnsupportedType();

      check(
        provideAnnotation != null,
        () => buildErrorMessage(
          error: JuggerErrorId.missing_provides_annotation,
          message:
              'Found static method ${moduleElement.name}.${element.name}, but is not annotated with @${j.provides.runtimeType}.',
        ),
      );
      _methods.add(StaticProvideMethod.fromMethodElement(element));
      return null;
    }

    if (element.isAbstract) {
      check(
        disposalHandlerAnnotation == null,
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_handler_method,
          message:
              'Method ${element.enclosingElement.name}.${element.name} marked with @${j.disposalHandler.runtimeType} must be static.',
        ),
      );

      element.returnType.checkUnsupportedType();
      check(
        bindAnnotation != null,
        () => buildErrorMessage(
          error: JuggerErrorId.missing_bind_annotation,
          message:
              'Found abstract method ${moduleElement.name}.${element.name}, but is not annotated with @${j.binds.runtimeType}.',
        ),
      );
      _methods.add(AbstractProvideMethod.fromMethodElement(element));
      return null;
    }

    throw UnexpectedJuggerError('Unsupported method of module $element');
  }

  @override
  String get subjectName => 'Module';
}

class _ComponentsVisitor extends RecursiveElementVisitor<dynamic> {
  List<Component> components = <Component>[];

  @override
  dynamic visitClassElement(ClassElement element) {
    final ComponentAnnotation? component =
        element.getComponentAnnotationOrNull();

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
      if (!methods.any(
        (MethodElement collectedMethod) => collectedMethod.name == element.name,
      )) {
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
      if (isCore(element)) {
        continue;
      }

      element.visitChildren(this);
    }
    return null;
  }
}

ComponentBuilder? getComponentBuilderFromTypeOrNull(DartType type) {
  final _ComponentBuildersVisitor visitor = _ComponentBuildersVisitor();

  final ClassElement? classElement = type.element as ClassElement?;
  if (classElement != null) {
    visitor.visitClassElement(classElement);
  }
  return visitor.componentBuilders.firstOrNull;
}

class _ComponentBuildersVisitor extends RecursiveElementVisitor<dynamic> {
  List<ComponentBuilder> componentBuilders = <ComponentBuilder>[];

  @override
  dynamic visitClassElement(ClassElement element) {
    final ComponentBuilderAnnotation? annotation =
        element.getComponentBuilderAnnotationOrNull();

    if (annotation != null) {
      check(
        element.isPublic,
        () => buildErrorMessage(
          error: JuggerErrorId.public_component_builder,
          message: 'Component builder ${element.name} must be public.',
        ),
      );
      final List<MethodElement> methods = element.getComponentBuilderMethods();

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
          buildMethod.returnType.element?.getComponentAnnotationOrNull();

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

      componentBuilders.add(
        ComponentBuilder(
          element: element,
          methods: methods,
          // ignore: avoid_as
          componentClass: buildMethod.returnType.element! as ClassElement,
        ),
      );
    }

    return null;
  }

  static const String buildMethodName = 'build';
}

class _ComponentBuilderMethodsVisitor extends RecursiveElementVisitor<dynamic>
    with CheckSupportedMemberMixin<dynamic> {
  final List<MethodElement> _methods = <MethodElement>[];

  @override
  dynamic visitConstructorElement(ConstructorElement element) => null;

  @override
  dynamic visitMethodElement(MethodElement element) {
    if (element.name == 'build') {
      final ComponentAnnotation? componentAnnotation =
          element.returnType.element?.getComponentAnnotationOrNull();
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

  @override
  String get subjectName => 'ComponentBuilder';
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
          continue;
        }

        super.visitElement(interfaceElement);
      }
    }
    return super.visitElement(element);
  }

  @override
  dynamic visitMethodElement(MethodElement method) {
    _methods.add(method);
    return super.visitMethodElement(method);
  }
}

class _ComponentMembersVisitor extends GeneralizingElementVisitor<dynamic>
    with CheckSupportedMemberMixin<dynamic> {
  final Map<String, ComponentMethod> _members = <String, ComponentMethod>{};

  @override
  dynamic visitFieldElement(FieldElement element) => null;

  @override
  dynamic visitElement(Element element) {
    if (element is ConstructorElement) {
      final List<InterfaceType> allSupertypes =
          element.enclosingElement.allSupertypes;

      for (final InterfaceType interfaceType in allSupertypes) {
        final Element interfaceElement = interfaceType.element;
        if (isCore(interfaceElement)) {
          continue;
        }

        super.visitElement(interfaceElement);
      }
    }
    return super.visitElement(element);
  }

  @override
  dynamic visitMethodElement(MethodElement method) {
    check(
      !method.isOperator,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_member,
        message: 'Unsupported member ${method.name} in $subjectName.',
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

    if (method.name == 'dispose') {
      check(
        method.returnType.getName() == 'Future<void>',
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_handler_method,
          message:
              'Dispose method ${method.name} of component must have type Future<void>.',
        ),
      );

      check(
        method.parameters.isEmpty,
        () => buildErrorMessage(
          error: JuggerErrorId.invalid_handler_method,
          message:
              'Disposal method ${method.name} of component must have zero parameters.',
        ),
      );

      _members.putIfAbsent(method.name, () => const DisposeMethod());
      return null;
    }

    // It is method for inject object.
    if (method.returnType is VoidType) {
      check(
        method.parameters.length == 1,
        () {
          return buildErrorMessage(
            error: JuggerErrorId.invalid_injectable_method,
            message: 'Injected method ${method.name} must have one parameter.',
          );
        },
      );
      _members.putIfAbsent(
        method.name,
        () => MemberInjectorMethod(method),
      );
      return null;
    }
    // It is method for access of object.

    check(
      method.parameters.isEmpty,
      () {
        return buildErrorMessage(
          error: JuggerErrorId.invalid_method_of_component,
          message:
              'Method ${method.name} of component must have zero parameters.',
        );
      },
    );

    _members.putIfAbsent(
      method.name,
      () => MethodObjectAccessor(method),
    );

    return null;
  }

  @override
  dynamic visitPropertyAccessorElement(PropertyAccessorElement property) {
    check(
      !property.isSetter,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_member,
        message: 'Unsupported member ${property.name} in $subjectName.',
      ),
    );

    check(
      property.isAbstract,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_method_of_component,
        message: 'Accessor ${property.name} of component must be abstract.',
      ),
    );
    _members.putIfAbsent(
      property.name,
      () => PropertyObjectAccessor(property),
    );
    return null;
  }

  @override
  String get subjectName => 'Component';
}

/// An visitor that will throw an exception if any of the visit methods that
/// are invoked have not been overridden.
mixin CheckSupportedMemberMixin<R> on ElementVisitor<R> {
  String get subjectName;

  @override
  R? visitClassElement(ClassElement element) => _throw(element);

  @override
  R? visitCompilationUnitElement(CompilationUnitElement element) =>
      _throw(element);

  @override
  R? visitExportElement(ExportElement element) => _throw(element);

  @override
  R? visitExtensionElement(ExtensionElement element) => _throw(element);

  @override
  R? visitFieldElement(FieldElement element) => _throw(element);

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) =>
      _throw(element);

  @override
  R? visitFunctionElement(FunctionElement element) => _throw(element);

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) =>
      _throw(element);

  @override
  R? visitImportElement(ImportElement element) => _throw(element);

  @override
  R? visitLabelElement(LabelElement element) => _throw(element);

  @override
  R? visitLibraryElement(LibraryElement element) => _throw(element);

  @override
  R? visitLocalVariableElement(LocalVariableElement element) => _throw(element);

  @override
  R? visitMethodElement(MethodElement element) => _throw(element);

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) =>
      _throw(element);

  @override
  R? visitParameterElement(ParameterElement element) => _throw(element);

  @override
  R? visitPrefixElement(PrefixElement element) => _throw(element);

  @override
  R? visitPropertyAccessorElement(PropertyAccessorElement element) =>
      _throw(element);

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) =>
      _throw(element);

  @override
  R? visitTypeAliasElement(TypeAliasElement element) => _throw(element);

  @override
  R? visitTypeParameterElement(TypeParameterElement element) => _throw(element);

  R _throw(Element element) {
    throw JuggerError(
      buildErrorMessage(
        error: JuggerErrorId.invalid_member,
        message: 'Unsupported member ${element.name} in $subjectName.',
      ),
    );
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

  /// Returns all provides and binds methods of module and validate them. The
  /// client must check that the element is a module.
  List<ProvideMethod> getProvides() {
    return getModuleMethods()
        .whereType<ProvideMethod>()
        .cast<ProvideMethod>()
        .toList();
  }

  List<ModuleMethod> getModuleMethods() {
    final _ModuleMethodsVisitor visitor = _ModuleMethodsVisitor();
    visitChildren(visitor);
    return visitor._methods;
  }

  List<DisposalHandlerMethod> getDisposalHandlerMethods() {
    return getModuleMethods()
        .whereType<DisposalHandlerMethod>()
        .cast<DisposalHandlerMethod>()
        .toList();
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

  /// Returns all members of the component and validate them. Will throw an
  /// error if the component contains an unsupported member. The client must
  /// check that the element is a component.
  List<ComponentMethod> getComponentMembers() {
    final _ComponentMembersVisitor visitor = _ComponentMembersVisitor();
    visitChildren(visitor);
    return visitor._members.values.toList(growable: false);
  }

  List<MethodElement> getMethods() {
    final _MethodsVisitor visitor = _MethodsVisitor();
    visitChildren(visitor);
    return visitor._methods;
  }
}
