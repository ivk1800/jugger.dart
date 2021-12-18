import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:jugger/jugger.dart' as j;

import 'classes.dart';
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
        throw StateError(
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
    check(
      moduleElement.hasAnnotatedAsModule(),
      'class [${moduleElement.name}] ${moduleElement.library!.identifier} must be annotated as ${j.module.runtimeType}',
    );

    final List<Annotation> annotations = getAnnotations(element);

    if (!element.isAbstract && !element.isStatic) {
      throw StateError(
        'provided method must be abstract or static [${moduleElement.name}.${element.name}]',
      );
    }

    if (element.isPrivate) {
      throw StateError(
        'provided method can not be private [${moduleElement.name}.${element.name}]',
      );
    }

    if (element.isStatic) {
      check(getProvideAnnotation(element) != null,
          'provide static method [${moduleElement.name}.${element.name}] must be annotated [${j.provide.runtimeType}]');
    }

    if (element.isAbstract) {
      check(getBindAnnotation(element) != null,
          'provide abstract method [${moduleElement.name}.${element.name}] must be annotated [${j.bind.runtimeType}]');
      check(element.parameters.length == 1,
          'method [${moduleElement.name}.${element.name}] annotates [${j.bind.runtimeType}] must have 1 parameter');
      // ignore: flutter_style_todos
      //TODO: check parameter type must be assignable to the return type
    }

    if (getBindAnnotation(element) != null &&
        getProvideAnnotation(element) != null) {
      throw StateError(
        'provide method [${moduleElement.name}.${element.name}] can not be annotated together [${j.provide.runtimeType}] and [${j.bind.runtimeType}]',
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
      throw StateError(
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

class ComponentBuildersVisitor extends RecursiveElementVisitor<dynamic> {
  List<ComponentBuilder> componentBuilders = <ComponentBuilder>[];

  @override
  dynamic visitClassElement(ClassElement element) {
    final ComponentBuilderAnnotation? annotation =
        getComponentBuilderAnnotation(element);

    if (annotation != null) {
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

      final ComponentAnnotation? componentAnnotation =
          getComponentAnnotation(v.buildMethod.returnType.element!);

      check(componentAnnotation != null, 'build method must return component');

      for (DependencyAnnotation dep in componentAnnotation!.dependencies) {
        final bool dependencyProvided = v.methodElements
            .where((MethodElement me) => me.name != 'build')
            .any((MethodElement me) {
          check(me.parameters.length == 1,
              'build method (${me.name}) must have 1 parameter');
          return me.parameters[0].type.element == dep.element;
        });

        check(dependencyProvided,
            'dependency (${dep.element.name}) must provided by build method');
      }

      componentBuilders.add(ComponentBuilder(
          element: element,
          methods: v.methodElements,
          // ignore: avoid_as
          componentClass: v.buildMethod.returnType.element as ClassElement));
    }

    return null;
  }
}

class BuildMethodsVisitor extends RecursiveElementVisitor<dynamic> {
  List<MethodElement> methodElements = <MethodElement>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    if (element.name == 'build') {
      final ComponentAnnotation? componentAnnotation =
          getComponentAnnotation(element.returnType.element!);
      if (componentAnnotation == null) {
        throw StateError(
          'build $element method must return component type',
        );
      }
    }
    methodElements.add(element);
    return null;
  }

  MethodElement get buildMethod {
    return methodElements.firstWhere((MethodElement m) {
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
      throw StateError(
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
