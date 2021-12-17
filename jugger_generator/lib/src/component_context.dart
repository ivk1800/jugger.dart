import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:jugger_generator/src/classes.dart';
import 'package:jugger_generator/src/classes.dart' as j;
import 'package:jugger_generator/src/utils.dart';
import 'package:jugger_generator/src/visitors.dart';
import 'package:quiver/core.dart';

class ComponentContext {
  ComponentContext({
    required this.component,
    required this.componentBuilder,
  });

  ComponentContext.fromComponent({
    required this.component,
    required this.componentBuilder,
  }) {
    for (j.DependencyAnnotation dep in component.dependencies) {
      final ProvideMethodVisitor v = ProvideMethodVisitor();
      dep.element.visitChildren(v);

      for (MethodElement m in v.methods) {
        providerSources.add(AnotherComponentSource(
            // ignore: avoid_as
            providedClass: m.returnType.element as ClassElement,
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
          // ignore: avoid_as
          moduleClass: element.enclosingElement as ClassElement,
          // ignore: avoid_as
          providedClass: element.returnType.element as ClassElement,
          method: method,
          annotations: getAnnotations(element)));
    }

    for (ParameterElement parameter
        in component.buildInstanceFields(componentBuilder)) {
      providerSources.add(BuildInstanceSource(
          parameter: parameter,
          // ignore: avoid_as
          providedClass: parameter.type.element as ClassElement,
          annotations: getAnnotations(parameter.enclosingElement!)));
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
        parameter.type.element!.visitChildren(visitor);

        for (j.InjectedMember member in visitor.members) {
          _registerDependency(member.element);
        }
      }
    }
  }

  final Map<_Key, Dependency> _dependencies = HashMap<_Key, Dependency>();
  final j.Component component;
  final j.ComponentBuilder? componentBuilder;

  final List<ProviderSource> providerSources = <ProviderSource>[];

  List<Dependency> get dependencies => _dependencies.values.toList()
    ..sort((Dependency a, Dependency b) =>
        a.element.name.compareTo(b.element.name));

  List<ClassElement> get dependenciesClasses =>
      _dependencies.values.map((Dependency d) => d.element).toList();

  Dependency _registerDependency(Element element) {
    final String? named = getNamedAnnotation(element)?.name;

    final _Key key = _Key.of(element, named);

    if (_dependencies.containsKey(key)) {
      return _dependencies[key]!;
    }

    if (element is MethodElement) {
      final Dependency dependency = Dependency(
        named,
        // ignore: avoid_as
        element.returnType.element as ClassElement,
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

  Dependency _registerVariableElementDependency(Element element) {
    if (!(element is VariableElement)) {
      throw StateError('element[$element] is not VariableElement');
    }

    final String? named = getNamedAnnotation(element)?.name;

    final _Key key = _Key.of(element, named);

//    if (isCore(element.type.element)) {
//      final _Dependency dependency =
//      _Dependency(element.type.element as ClassElement, <_Dependency>[]);
//      _dependencies[key] = dependency;
//      return dependency;
//    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.type.element!.visitChildren(visitor);

    if (visitor.injectedConstructors.isEmpty) {
      final Dependency dependency = Dependency(
        named,
        // ignore: avoid_as
        element.type.element as ClassElement,
        <Dependency>[],
        element.enclosingElement!,
      );
      _dependencies[key] = dependency;
      return dependency;
    }

    check(visitor.injectedConstructors.length == 1,
        'too many injected constructors for ${element.type.getName()}');

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
    final j.Method? provideMethod = findProvideMethod(parameter.type);

    if (provideMethod != null) {
      _registerDependency(provideMethod.element);
    }
  }

  j.Method? findProvideMethod(DartType type, [String? name]) {
    return component.provideMethods.firstWhereOrNull((j.Method method) =>
        method.element.returnType.getName() == type.getName() &&
        method.named == name);
  }

  ProviderSource? findProvider(Element element, [String? name]) {
    if (!(element is ClassElement)) {
      throw StateError('element[$element] is not ClassElement');
    }
    return providerSources.firstWhereOrNull((ProviderSource source) {
      return source.providedClass == element && source.named == name;
    });
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
  _Key({required this.named, required this.type, required this.path})
      : assert(type.element is ClassElement);

  factory _Key.of(Element element, String? named) {
    if (element is MethodElement) {
      return _Key(
          named: named,
          type: element.returnType,
          path: createElementPath(element.returnType.element!));
    } else if (element is VariableElement) {
      return _Key(
          named: named,
          type: element.type,
          path: createElementPath(element.type.element!));
    }

    throw StateError(
      'field ${element.name} unsupported type',
    );
  }

  final DartType type;
  final String path;
  final String? named;

  @override
  bool operator ==(dynamic o) =>
      o is _Key && type == o.type && path == o.path && named == o.named;

  @override
  int get hashCode => hash3(type.hashCode, path.hashCode, named.hashCode);

  @override
  String toString() {
    final Element? element = type.element;
    if (element is MethodElement) {
      final MethodElement m = element;
      return m.returnType.getName();
    } else if (element is ParameterElement) {
      final ParameterElement p = element;
      return p.type.getName();
    }

    throw StateError(
      'field ${element!.name} unsupported type',
    );
  }
}

class Dependency {
  const Dependency(
      this.named, this.element, this.dependencies, this.enclosingElement);

  final ClassElement element;
  final Element enclosingElement;
  final List<Dependency> dependencies;
  final String? named;

  @override
  String toString() {
    return element.thisType.getName();
  }
}

abstract class ProviderSource {
  ProviderSource(this.providedClass, this.annotations);

  final ClassElement providedClass;

  dynamic get key {
    final j.NamedAnnotation? named = namedAnnotation;
    if (named != null) {
      return '${named.name}_${createElementPath(providedClass)}/${providedClass.name}';
    }

    return providedClass;
  }

  j.NamedAnnotation? get namedAnnotation {
    final Annotation? annotation = annotations
        .firstWhereOrNull((j.Annotation a) => a is j.NamedAnnotation);
    return annotation is NamedAnnotation ? annotation : null;
  }

  String? get named => namedAnnotation?.name;

  String get sourceString;

  final List<j.Annotation> annotations;
}

class ModuleSource extends ProviderSource {
  ModuleSource({
    required this.moduleClass,
    required ClassElement providedClass,
    required List<j.Annotation> annotations,
    required this.method,
  }) : super(providedClass, annotations);

  final ClassElement moduleClass;

  final j.Method method;

  @override
  String get sourceString => '${moduleClass.name}.${method.element.name}';
}

class BuildInstanceSource extends ProviderSource {
  BuildInstanceSource({
    required ClassElement providedClass,
    required this.parameter,
    required List<j.Annotation> annotations,
  }) : super(providedClass, annotations);

  final ParameterElement parameter;

  String get assignString {
    final j.NamedAnnotation? named = namedAnnotation;
    if (named != null) {
      return '_${named.name}${parameter.type.getName()}';
    }

    return '_${uncapitalize(parameter.type.getName())}';
  }

  @override
  String get sourceString => '${parameter.type.getName()} ${parameter.name}';
}

class AnotherComponentSource extends ProviderSource {
  AnotherComponentSource({
    required ClassElement providedClass,
    required this.method,
    required this.dependencyClass,
    required List<j.Annotation> annotations,
  }) : super(providedClass, annotations);

  ///
  /// example: _appComponent
  ///
  final ClassElement dependencyClass;
  final MethodElement method;

  ///
  /// example: _appComponent.getFoldersRouter()
  ///
  String get assignString {
    return '_${uncapitalize(dependencyClass.name)}.${method.name}()';
  }

  @override
  String get sourceString =>
      '${providedClass.thisType.getName()}.${method.name}';
}
