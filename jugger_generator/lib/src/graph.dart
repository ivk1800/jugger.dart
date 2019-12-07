import 'dart:collection';
import 'dart:math';
import 'package:code_builder/code_builder.dart';
import "package:collection/collection.dart";

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:jugger_generator/src/utils.dart';
import 'package:meta/meta.dart';
import 'package:jugger_generator/src/classes.dart' as j;
import 'package:jugger_generator/src/visitors.dart';
import 'package:quiver/core.dart';

class Graph {
  Graph(this.component, this.componentBuilder);

  Graph.fromComponent(this.component, this.componentBuilder) {
    for (j.DependencyAnnotation dep in component.dependencies) {
      ProvideMethodVisitor v = ProvideMethodVisitor();
      dep.element.visitChildren(v);

      for (MethodElement m in v.methods) {
        providerSources.add(AnotherComponentSource(
            providedClass: m.returnType.element,
            method: m,
            dependencyClass: dep.element
        ));
      }
    }

    if (component.dependencies.isNotEmpty) {
      assert(componentBuilder !=
          null, 'you need provide dependencies by builder. '
          'component: ${component.element.name}, dependencies: ${component.dependencies.map((
          j.DependencyAnnotation de) => de.element.name).join(',')}');
    }

    for (j.Method method in component.provideMethods) {
      final MethodElement element = method.element;

      providerSources.add(ModuleSource(
          moduleClass: element.enclosingElement,
          providedClass: element.returnType.element,
          method: method
      ));
    }

    for (ParameterElement parameter in component.buildInstanceFields(componentBuilder)) {
      providerSources.add(BuildInstanceSource(
        parameter: parameter,
        providedClass: parameter.type.element
      ));
    }

    _validateProviderSources();

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
  final j.ComponentBuilder componentBuilder;

  final List<ProviderSource> providerSources = <ProviderSource>[];

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

//    if (isCore(element.type.element)) {
//      final _Dependency dependency =
//      _Dependency(element.type.element as ClassElement, <_Dependency>[]);
//      _dependencies[key] = dependency;
//      return dependency;
//    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.type.element.visitChildren(visitor);

    if (visitor.injectedConstructors.isEmpty) {
      final _Dependency dependency =
      _Dependency(element.type.element as ClassElement, <_Dependency>[]);
      _dependencies[key] = dependency;
      return dependency;
    }

    assert(visitor.injectedConstructors.length == 1,
        'too many injected constructors for ${element.type.name}');

    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];

    final List<_Dependency> dependencies = injectedConstructor
        .element.parameters
        .map((ParameterElement parameter) {
      _registerParamDependencyIfNeed(parameter);
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
          _registerParamDependencyIfNeed(parameter);
      return _registerDependency(parameter);
    }).toList();

    return dependencies;
  }

  void _registerParamDependencyIfNeed(ParameterElement parameter) {
    final j.Method provideMethod = component.provideMethods.firstWhere(
            (j.Method method) =>
        method.element.returnType.name == parameter.type.name,
        orElse: () => null);

    if (provideMethod != null) {
      _registerDependency(provideMethod.element);
    }
  }

  ProviderSource findProvider(ClassElement element) {
    return providerSources.firstWhere((ProviderSource source)  {
      return source.providedClass == element;
    }, orElse: () => null);
  }

  void _validateProviderSources() {
    final groupBy2 = groupBy(providerSources, (ProviderSource source) {
      return source.providedClass;
    });

    groupBy2.forEach((ClassElement element, List<ProviderSource> p) {
      assert(p.length == 1, '${element.thisType} has several providers: ${p
          .map((ProviderSource s) => s.sourceString)
          .join(', ')}');
    });
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

abstract class ProviderSource {

  ProviderSource(this.providedClass);

  final ClassElement providedClass;

  String  get sourceString;
}

class ModuleSource extends ProviderSource {

  ModuleSource({
    @required this.moduleClass,
    @required ClassElement providedClass,
    @required this.method,
  }) : super(providedClass);

  final ClassElement moduleClass;

  final j.Method method;

  @override
  String get sourceString => '${moduleClass.name}.${method.element.name}';
}

class BuildInstanceSource extends ProviderSource {

  BuildInstanceSource({
    @required ClassElement providedClass,
    @required this.parameter,
  }) : super(providedClass);

  final ParameterElement parameter;

  String get assignString {
    return '_${uncapitalize(parameter.type.name)}';
  }

  @override
  String get sourceString => '${parameter.type.name} ${parameter.name}';
}

class AnotherComponentSource extends ProviderSource {

  AnotherComponentSource({
    @required ClassElement providedClass,
    @required this.method,
    @required this.dependencyClass,
  }) : super(providedClass);

  final ClassElement dependencyClass;
  final MethodElement method;

  String get assignString {
    return '_${uncapitalize(dependencyClass.name)}.${method.name}()';
  }

  @override
  String get sourceString => '${providedClass.thisType.name}.${method.name}';
}