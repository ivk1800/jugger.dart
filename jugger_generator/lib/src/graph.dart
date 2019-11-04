import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:jugger_generator/src/utils.dart';
import 'package:meta/meta.dart';
import 'package:jugger_generator/src/classes.dart' as j;
import 'package:jugger_generator/src/visitors.dart';
import 'package:quiver/core.dart';

class Graph {
  Graph(this.component);

  Graph.fromComponent(this.component) {
    for (j.Method method in component.provideMethods) {
      final MethodElement element = method.element;
      _registerDependency(element);
    }

    for (j.MemberInjectorMethod method in component.methods) {
      final MethodElement element = method.element;

      for (ParameterElement parameter in element.parameters) {
        final InjectedMembersVisitor visitor = InjectedMembersVisitor();
        parameter.type.element.visitChildren(visitor);

        for (j.InjectedMember member in visitor.members) {
          _registerDependency(member.element);
        }
      }
    }
  }

  final Map<_Key, _Dependency> _dependencies = HashMap<_Key, _Dependency>();
  final j.Component component;

  List<ClassElement> get dependenciesClasses =>
      _dependencies.values.map((_Dependency d) => d.element).toList();

  _Dependency _registerDependency(Element element) {
    final _Key key = _Key.of(element);

    if (_dependencies.containsKey(key)) {
      return _dependencies[key];
    }

    if (element is MethodElement) {
      final _Dependency dependency = _Dependency(
          element.returnType.element, _registerMethodDependencies(element));
      _dependencies[key] = dependency;
      return dependency;
    } else if (element is ParameterElement || element is FieldElement) {
      return _registerVariableElementDependency(element);
    }

    throw StateError(
      'field ${element.name} unsupported type',
    );
  }

  _Dependency _registerVariableElementDependency(VariableElement element) {
    _Key key = _Key.of(element);

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.type.element.visitChildren(visitor);

    assert(visitor.injectedConstructors.length == 1,
        'not found injected constructor or provider for ${element.type.name}');

    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];

    final List<_Dependency> dependencies = injectedConstructor
        .element.parameters
        .map((ParameterElement parameter) {
      return _registerDependency(parameter);
    }).toList();

    final _Dependency dependency =
        _Dependency(element.type.element as ClassElement, dependencies);
    _dependencies[key] = dependency;
    return dependency;
  }

  List<_Dependency> _registerMethodDependencies(MethodElement element) {
    final List<_Dependency> dependencies =
        element.parameters.map((ParameterElement parameter) {
      final j.Method provideMethod = component.provideMethods.firstWhere(
          (j.Method method) =>
              method.element.returnType.name == parameter.type.name,
          orElse: () => null);

      if (provideMethod != null) {
        _registerDependency(provideMethod.element);
      }
      return _registerDependency(parameter);
    }).toList();

    return dependencies;
  }
}

class _Key {
  _Key({@required this.type, @required this.path})
      : assert(type.element is ClassElement);

  factory _Key.of(Element element) {
    if (element is MethodElement) {
      return _Key(
          type: element.returnType,
          path: createElementPath(element.returnType.element));
    } else if (element is VariableElement) {
      return _Key(
          type: element.type, path: createElementPath(element.type.element));
    }

    throw StateError(
      'field ${element.name} unsupported type',
    );
  }

  final DartType type;
  final String path;

  @override
  bool operator ==(dynamic o) => o is _Key && type == o.type && path == o.path;

  @override
  int get hashCode => hash2(type.hashCode, path.hashCode);

  @override
  String toString() {
    final Element element = type.element;
    if (element is MethodElement) {
      MethodElement m = element;
      return m.returnType.name;
    } else if (element is ParameterElement) {
      ParameterElement p = element;
      return p.type.name;
    }

    throw StateError(
      'field ${element.name} unsupported type',
    );
  }
}

class _Dependency {
  const _Dependency(this.element, this.dependencies);

  final ClassElement element;
  final List<_Dependency> dependencies;

  @override
  String toString() {
    return element.thisType.name;
  }
}
