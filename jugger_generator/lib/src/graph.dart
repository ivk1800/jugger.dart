import 'dart:collection';
import 'package:collection/collection.dart';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:jugger_generator/src/classes.dart';
import 'package:jugger_generator/src/utils.dart';
import 'package:meta/meta.dart';
import 'package:jugger_generator/src/classes.dart' as j;
import 'package:jugger_generator/src/visitors.dart';
import 'package:quiver/core.dart';

class Graph {
  Graph(this.component, this.componentBuilder);

  Graph.fromComponent(this.component, this.componentBuilder) {
    for (j.DependencyAnnotation dep in component.dependencies) {
      final ProvideMethodVisitor v = ProvideMethodVisitor();
      dep.element.visitChildren(v);

      for (MethodElement m in v.methods) {
        providerSources.add(AnotherComponentSource(
            providedClass: m.returnType.element,
            method: m,
            dependencyClass: dep.element,
            annotations: getAnnotations(m)));
      }
    }

    if (component.dependencies.isNotEmpty) {
      check(
          componentBuilder != null,
          'you need provide dependencies by builder. '
          'component: ${component.element.name}, dependencies: ${component.dependencies.map((j.DependencyAnnotation de) => de.element.name).join(',')}');
    }

    for (j.Method method in component.provideMethods) {
      final MethodElement element = method.element;

      providerSources.add(ModuleSource(
          moduleClass: element.enclosingElement,
          providedClass: element.returnType.element,
          method: method,
          annotations: getAnnotations(element)));
    }

    for (ParameterElement parameter
        in component.buildInstanceFields(componentBuilder)) {
      providerSources.add(BuildInstanceSource(
          parameter: parameter,
          providedClass: parameter.type.element,
          annotations: getAnnotations(parameter.enclosingElement)));
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

  final Map<_Key, Dependency> _dependencies = HashMap<_Key, Dependency>();
  final j.Component component;
  final j.ComponentBuilder componentBuilder;

  final List<ProviderSource> providerSources = <ProviderSource>[];

  List<Dependency> get dependencies => _dependencies.values.toList();

  List<ClassElement> get dependenciesClasses =>
      _dependencies.values.map((Dependency d) => d.element).toList();

  Dependency _registerDependency(Element element) {
    final String named = getNamedAnnotation(element)?.name;

    final _Key key = _Key.of(element, named);

    if (_dependencies.containsKey(key)) {
      return _dependencies[key];
    }

    if (element is MethodElement) {
      final Dependency dependency = Dependency(
        named,
        element.returnType.element,
        _registerMethodDependencies(element),
        element,
      );
      _dependencies[key] = dependency;
      return dependency;
    } else if (element is ParameterElement || element is FieldElement) {
      return _registerVariableElementDependency(element);
    }

    throw StateError(
      'field ${element.name} unsupported type',
    );
  }

  Dependency _registerVariableElementDependency(VariableElement element) {
    final String named = getNamedAnnotation(element)?.name;

    final _Key key = _Key.of(element, named);

//    if (isCore(element.type.element)) {
//      final _Dependency dependency =
//      _Dependency(element.type.element as ClassElement, <_Dependency>[]);
//      _dependencies[key] = dependency;
//      return dependency;
//    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.type.element.visitChildren(visitor);

    if (visitor.injectedConstructors.isEmpty) {
      final Dependency dependency = Dependency(
        named,
        // ignore: avoid_as
        element.type.element as ClassElement,
        <Dependency>[],
        element.enclosingElement,
      );
      _dependencies[key] = dependency;
      return dependency;
    }

    check(visitor.injectedConstructors.length == 1,
        'too many injected constructors for ${element.type.name}');

    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];

    final List<Dependency> dependencies = injectedConstructor.element.parameters
        .map((ParameterElement parameter) {
      _registerParamDependencyIfNeed(parameter);
      return _registerDependency(parameter);
    }).toList();

    final Dependency dependency = Dependency(
      named,
      // ignore: avoid_as
      element.type.element as ClassElement,
      dependencies,
      element,
    );
    _dependencies[key] = dependency;
    return dependency;
  }

  List<Dependency> _registerMethodDependencies(MethodElement element) {
    final List<Dependency> dependencies =
        element.parameters.map((ParameterElement parameter) {
      _registerParamDependencyIfNeed(parameter);
      return _registerDependency(parameter);
    }).toList();

    return dependencies;
  }

  void _registerParamDependencyIfNeed(ParameterElement parameter) {
    final j.Method provideMethod = findProvideMethod(parameter.type);

    if (provideMethod != null) {
      _registerDependency(provideMethod.element);
    }
  }

  j.Method findProvideMethod(DartType type, [String name]) {
    return component.provideMethods.firstWhere(
        (j.Method method) =>
            method.element.returnType.name == type.name && method.named == name,
        orElse: () => null);
  }

  ProviderSource findProvider(ClassElement element, [String name]) {
    return providerSources.firstWhere((ProviderSource source) {
      return source.providedClass == element && source.named == name;
    }, orElse: () => null);
  }

  List<ProviderSource> findProviders(ClassElement element) {
    return providerSources.where((ProviderSource source) {
      return source.providedClass == element;
    }).toList();
  }

  void _validateProviderSources() {
    final Map<dynamic, List<ProviderSource>> groupBy2 =
        groupBy<ProviderSource, dynamic>(providerSources,
            (ProviderSource source) {
      return source.key;
    });

    groupBy2.forEach((dynamic key, List<ProviderSource> p) {
      check(p.length == 1,
          '$key has several providers: ${p.map((ProviderSource s) => s.sourceString).join(', ')}');
    });
  }
}

class _Key {
  _Key({@required this.named, @required this.type, @required this.path})
      : assert(type.element is ClassElement);

  factory _Key.of(Element element, String named) {
    if (element is MethodElement) {
      return _Key(
          named: named,
          type: element.returnType,
          path: createElementPath(element.returnType.element));
    } else if (element is VariableElement) {
      return _Key(
          named: named,
          type: element.type,
          path: createElementPath(element.type.element));
    }

    throw StateError(
      'field ${element.name} unsupported type',
    );
  }

  final DartType type;
  final String path;
  final String named;

  @override
  bool operator ==(dynamic o) =>
      o is _Key && type == o.type && path == o.path && named == o.named;

  @override
  int get hashCode => hash3(type.hashCode, path.hashCode, named.hashCode);

  @override
  String toString() {
    final Element element = type.element;
    if (element is MethodElement) {
      final MethodElement m = element;
      return m.returnType.name;
    } else if (element is ParameterElement) {
      final ParameterElement p = element;
      return p.type.name;
    }

    throw StateError(
      'field ${element.name} unsupported type',
    );
  }
}

class Dependency {
  const Dependency(
      this.named, this.element, this.dependencies, this.enclosingElement);

  final ClassElement element;
  final Element enclosingElement;
  final List<Dependency> dependencies;
  final String named;

  @override
  String toString() {
    return element.thisType.name;
  }
}

abstract class ProviderSource {
  ProviderSource(this.providedClass, this.annotations);

  final ClassElement providedClass;

  dynamic get key {
    final j.NamedAnnotation named = namedAnnotation;
    if (named != null) {
      return '${named.name}_${createElementPath(providedClass)}/${providedClass.name}';
    }

    return providedClass;
  }

  j.NamedAnnotation get namedAnnotation =>
      annotations.firstWhere((j.Annotation a) => a is j.NamedAnnotation,
          orElse: () => null);

  String get named => namedAnnotation?.name;

  String get sourceString;

  final List<j.Annotation> annotations;
}

class ModuleSource extends ProviderSource {
  ModuleSource({
    @required this.moduleClass,
    @required ClassElement providedClass,
    @required List<j.Annotation> annotations,
    @required this.method,
  }) : super(providedClass, annotations);

  final ClassElement moduleClass;

  final j.Method method;

  @override
  String get sourceString => '${moduleClass.name}.${method.element.name}';
}

class BuildInstanceSource extends ProviderSource {
  BuildInstanceSource({
    @required ClassElement providedClass,
    @required this.parameter,
    @required List<j.Annotation> annotations,
  }) : super(providedClass, annotations);

  final ParameterElement parameter;

  String get assignString {
    final j.NamedAnnotation named = namedAnnotation;
    if (named != null) {
      return '_${named.name}${parameter.type.name}';
    }

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
    @required List<j.Annotation> annotations,
  }) : super(providedClass, annotations);

  final ClassElement dependencyClass;
  final MethodElement method;

  String get assignString {
    return '_${uncapitalize(dependencyClass.name)}.${method.name}()';
  }

  @override
  String get sourceString => '${providedClass.thisType.name}.${method.name}';
}
