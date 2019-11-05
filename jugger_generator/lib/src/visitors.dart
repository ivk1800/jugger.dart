import 'dart:math';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

import 'classes.dart';
import 'utils.dart';

class InjectedMembersVisitor extends RecursiveElementVisitor<dynamic> {
  final List<InjectedMember> members = <InjectedMember>[];

  @override
  dynamic visitFieldElement(FieldElement element) {
    final List<Annotation> annotations = getAnnotations(element);
    if (annotations
        .any((Annotation annotation) => annotation is InjectAnnotation)) {
      //TODO: check another states
      if (!element.isPublic || element.isStatic) {
        throw new StateError(
          'field ${element.name} must be only public',
        );
      }
      members.add(InjectedMember(element));
    }

    return null;
  }
}

class ProvidesVisitor extends RecursiveElementVisitor<dynamic> {
  final List<Method> methods = <Method>[];

  @override
  dynamic visitMethodElement(MethodElement element) {
    final List<Annotation> annotations = getAnnotations(element);

    if (!element.isAbstract && !element.isStatic) {
      throw StateError(
        'provided method must be abstract or static [${element.enclosingElement.name}.${element.name}]',
      );
    }

    if (element.isPrivate) {
      throw StateError(
        'provided method can not be private [${element.enclosingElement
            .name}.${element.name}]',
      );
    }

    if (element.isStatic) {
      assert(getProvideAnnotation(element) !=
          null, 'provide static method [${element.enclosingElement
          .name}.${element.name}] must be annotated [provide]');
    }

    if (element.isAbstract) {
      assert(getBindAnnotation(element) !=
          null, 'provide abstract method [${element.enclosingElement
          .name}.${element.name}] must be annotated [Bind]');
      assert(element.parameters.length == 1, 'method [${element.enclosingElement
          .name}.${element.name}] annotates [Bind] must have 1 parameter');
      //TODO: check parameter type must be assignable to the return type
    }

    if (getBindAnnotation(element) != null &&
        getProvideAnnotation(element) != null) {
      throw StateError(
        'provide method [${element
            .enclosingElement.name}.${element
            .name}] can not be annotated together [provide] and [bind]',
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
    final ComponentAnnotation component = getComponentAnnotation(element);

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
