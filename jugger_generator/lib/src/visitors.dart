import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart' as j;

import 'classes.dart';
import 'jugger_error.dart';
import 'messages.dart';
import 'utils.dart';

class InjectedMembersVisitor extends RecursiveElementVisitor<dynamic> {
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

      final InjectedMembersVisitor visitor = InjectedMembersVisitor();
      element.visitChildren(visitor);

      _addAll(visitor.members.map((InjectedMember m) => m.element).toList());
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

class ProvidesVisitor extends RecursiveElementVisitor<dynamic> {
  final List<Method> methods = <Method>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    final Element moduleElement = element.enclosingElement;
    check2(
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
      check(getProvideAnnotation(element) != null,
          'provide static method [${moduleElement.name}.${element.name}] must be annotated [${j.provides.runtimeType}]');
    }

    if (element.isAbstract) {
      check(getBindAnnotation(element) != null,
          'provide abstract method [${moduleElement.name}.${element.name}] must be annotated [${j.binds.runtimeType}]');
      check(element.parameters.length == 1,
          'method [${moduleElement.name}.${element.name}] annotates [${j.binds.runtimeType}] must have 1 parameter');
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

class InjectedFieldsVisitor extends RecursiveElementVisitor<dynamic> {
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

class ComponentsVisitor extends RecursiveElementVisitor<dynamic> {
  List<Component> components = <Component>[];

  @override
  dynamic visitClassElement(ClassElement element) {
    final ComponentAnnotation? component = getComponentAnnotation(element);

    if (component != null) {
      check2(element.isPublic, () => publicComponent(element));

      final InjectedFieldsVisitor fieldsVisitor = InjectedFieldsVisitor();
      element.visitChildren(fieldsVisitor);
      components.add(
        Component(
            element: element,
            annotations: <Annotation>[component],
            methods: fieldsVisitor.fields),
      );
    }
    return null;
  }
}

class InjectedConstructorsVisitor extends RecursiveElementVisitor<dynamic> {
  final List<InjectedConstructor> _constructors = <InjectedConstructor>[];

  @override
  dynamic visitConstructorElement(ConstructorElement element) {
    _constructors.add(InjectedConstructor(element));
    return null;
  }

  List<InjectedConstructor> get injectedConstructors => _constructors
      .where((InjectedConstructor constructor) => constructor.isInjected)
      .toList();
}

///
/// collect unique methods without repeating
///
class InjectedMethodsVisitor extends RecursiveElementVisitor<dynamic> {
  final Set<MethodElement> methods = <MethodElement>{};

  @override
  dynamic visitMethodElement(MethodElement element) {
    final List<Annotation> annotations = getAnnotations(element);

    if (annotations
        .any((Annotation annotation) => annotation is InjectAnnotation)) {
      if (!methods.any((MethodElement collectedMethod) =>
          collectedMethod.name == element.name)) {
        check2(
          !element.isStatic,
          () => 'injected method [${element.name}] can not be static',
        );
        check2(
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

class ComponentBuildersVisitor extends RecursiveElementVisitor<dynamic> {
  List<ComponentBuilder> componentBuilders = <ComponentBuilder>[];

  @override
  dynamic visitClassElement(ClassElement element) {
    final ComponentBuilderAnnotation? annotation =
        getComponentBuilderAnnotation(element);

    if (annotation != null) {
      check2(element.isPublic, () => publicComponentBuilder(element));
      final BuildMethodsVisitor v = BuildMethodsVisitor();
      element.visitChildren(v);

      for (int i = 0; i < v.methodElements.length; i++) {
        final MethodElement methodElement = v.methodElements[i];

        if (methodElement.name == 'build') {
          check(methodElement.parameters.isEmpty, 'build have > 1 parameter');
        } else {
          check(methodElement.returnType.getName() == element.name,
              '(${methodElement.name})  method return wrong type. Expected ${element.name}');
          check(methodElement.parameters.length == 1,
              '${methodElement.name} have > 1 parameter');
        }
      }

      late final MethodElement buildMethod;
      final MethodElement? buildMethodNullable = v.buildMethod;
      check(buildMethodNullable != null,
          'not found build method for [${createClassNameWithPath(element)}');
      buildMethod = buildMethodNullable!;

      final ComponentAnnotation? componentAnnotation =
          getComponentAnnotation(buildMethod.returnType.element!);

      check(componentAnnotation != null, 'build method must return component');

      final Iterable<MethodElement> externalDependenciesMethods = v
          .methodElements
          .where((MethodElement me) => me.name != BuildMethodName);
      for (DependencyAnnotation dep in componentAnnotation!.dependencies) {
        final bool dependencyProvided =
            externalDependenciesMethods.any((MethodElement me) {
          check(me.parameters.length == 1,
              'build method (${me.name}) must have 1 parameter');
          return me.parameters[0].type.element == dep.element;
        });

        check(dependencyProvided,
            'dependency (${dep.element.name}) must provided by build method');
      }

      for (MethodElement element in externalDependenciesMethods) {
        element.parameters.first.type.checkUnsupportedType();
      }

      componentBuilders.add(ComponentBuilder(
          element: element,
          methods: v.methodElements,
          // ignore: avoid_as
          componentClass: buildMethod.returnType.element as ClassElement));
    }

    return null;
  }

  static const String BuildMethodName = 'build';
}

class BuildMethodsVisitor extends RecursiveElementVisitor<dynamic> {
  List<MethodElement> methodElements = <MethodElement>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    if (element.name == 'build') {
      final ComponentAnnotation? componentAnnotation =
          getComponentAnnotation(element.returnType.element!);
      if (componentAnnotation == null) {
        throw JuggerError(
          'build $element method must return component type',
        );
      }
    }
    methodElements.add(element);
    return null;
  }

  MethodElement? get buildMethod {
    return methodElements.firstWhereOrNull((MethodElement m) {
      return m.name == 'build';
    });
  }
}

class BuildInstanceFieldsVisitor extends RecursiveElementVisitor<dynamic> {
  List<FieldElement> fields = <FieldElement>[];

  @override
  dynamic visitFieldElement(FieldElement element) {
    fields.add(element);
    return null;
  }
}

class ProvideMethodVisitor extends RecursiveElementVisitor<dynamic> {
  List<MethodElement> methods = <MethodElement>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    if (element.returnType.getName() == 'void') {
      return null;
    }

    if (!element.isAbstract) {
      throw JuggerError(
        '${element.name} not abstract',
      );
    }

    methods.add(element);
    return null;
  }
}

class ProvidePropertyVisitor extends RecursiveElementVisitor<dynamic> {
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
