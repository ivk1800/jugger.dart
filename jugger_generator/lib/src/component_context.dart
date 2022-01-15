import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:jugger_generator/src/classes.dart';
import 'package:jugger_generator/src/classes.dart' as j;
import 'package:jugger_generator/src/utils.dart';
import 'package:jugger_generator/src/visitors.dart';
import 'package:quiver/core.dart';

import 'jugger_error.dart';

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
      final ProvideMethodVisitor methodVisitor = ProvideMethodVisitor();
      dep.element.visitChildren(methodVisitor);

      final ProvidePropertyVisitor propertyVisitor = ProvidePropertyVisitor();
      dep.element.visitChildren(propertyVisitor);

      for (MethodElement m in methodVisitor.methods) {
        providerSources.add(AnotherComponentSource(
            type: m.returnType,
            element: m,
            dependencyClass: dep.element,
            annotations: getAnnotations(m)));
      }

      for (PropertyAccessorElement property in propertyVisitor.properties) {
        providerSources.add(
          AnotherComponentSource(
            type: property.returnType,
            element: property,
            dependencyClass: dep.element,
            annotations: getAnnotations(property),
          ),
        );
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
          type: element.returnType,
          method: method,
          annotations: getAnnotations(element)));
    }

    for (ParameterElement parameter
        in component.buildInstanceFields(componentBuilder)) {
      providerSources.add(BuildInstanceSource(
          parameter: parameter,
          // ignore: avoid_as
          type: parameter.type,
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
    ..sort((Dependency a, Dependency b) => a.compareTo(b));

  final Queue<_Key> _dependenciesQueue = Queue<_Key>();

  // List<ClassElement> get dependenciesClasses =>
  //     _dependencies.values.map((Dependency d) => d.element).toList();

  Dependency _registerDependency(Element element) {
    final String? named = getQualifierAnnotation(element)?.tag;

    final _Key key = _Key.of(element, named);

    if (_dependenciesQueue.contains(key)) {
      _dependenciesQueue.addFirst(key);
      throw JuggerError(
        'Found circular dependency! ${_dependenciesQueue.toList().reversed.join('->')}',
      );
    }
    _dependenciesQueue.addFirst(key);

    if (_dependencies.containsKey(key)) {
      _dependenciesQueue.removeFirst();
      return _dependencies[key]!;
    }

    if (element is MethodElement) {
      final Dependency dependency = Dependency(
        named,
        element.returnType,
        _registerMethodDependencies(element),
        element,
      );
      _dependencies[key] = dependency;
      _dependenciesQueue.removeFirst();
      return dependency;
    } else if (element is ParameterElement || element is FieldElement) {
      _dependenciesQueue.removeFirst();
      return _registerVariableElementDependency(element);
    }

    throw JuggerError(
      'field ${element.name} unsupported type',
    );
  }

  Dependency _registerVariableElementDependency(Element element) {
    if (!(element is VariableElement)) {
      throw JuggerError('element[$element] is not VariableElement');
    }

    final String? named = getQualifierAnnotation(element)?.tag;

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
        element.type,
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

    final ConstructorElement constructorElement = injectedConstructor.element;
    late final String constructorLogName =
        '${element.type.getName()}.${constructorElement.name}';

    check(
      !constructorElement.isPrivate,
      'constructor can not be private [$constructorLogName]',
    );
    check(
      !constructorElement.isFactory,
      'factory constructor not supported [$constructorLogName]',
    );
    check(
      constructorElement.name.isEmpty,
      'named constructor not supported [$constructorLogName]',
    );

    final List<Dependency> dependencies =
        constructorElement.parameters.map((ParameterElement parameter) {
      _registerParamDependencyIfNeed(parameter);
      return _registerDependency(parameter);
    }).toList();

    final Dependency dependency = Dependency(
      named,
      element.type,
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
    return component.provideMethods.firstWhereOrNull((j.Method method) {
      return method.element.returnType == type && method.named == name;
    });
  }

  ProviderSource? findProvider(DartType type, [String? tag]) {
    // if (!(element is ClassElement)) {
    //   throw JuggerError('element[$element] is not ClassElement');
    // }
    return providerSources.firstWhereOrNull((ProviderSource source) {
      return source.type == type && source.tag == tag;
    });
  }

  // List<ProviderSource> findProviders(ClassElement element) {
  //   return providerSources.where((ProviderSource source) {
  //     return source.providedClass == element;
  //   }).toList();
  // }

  void _validateProviderSources() {
    final Map<dynamic, List<ProviderSource>> groupBy2 =
        groupBy<ProviderSource, dynamic>(providerSources,
            (ProviderSource source) {
      return source.key;
    });

    groupBy2.forEach((dynamic key, List<ProviderSource> p) {
      check(p.length == 1,
          '$key provides multiple time: ${p.map((ProviderSource s) => s.sourceString).join(', ')}');
    });
  }
}

class _Key {
  _Key({
    required this.named,
    required this.type,
    required this.element,
    required this.path,
  }) : assert(type.element is ClassElement);

  factory _Key.of(Element element, String? named) {
    if (element is MethodElement) {
      return _Key(
        named: named,
        element: element,
        type: element.returnType,
        path: createElementPath(element.returnType.element!),
      );
    } else if (element is VariableElement) {
      return _Key(
        named: named,
        element: element,
        type: element.type,
        path: createElementPath(element.type.element!),
      );
    }

    throw JuggerError(
      'field ${element.name} unsupported type',
    );
  }

  final Element element;
  final DartType type;
  final String path;
  final String? named;

  @override
  bool operator ==(dynamic o) =>
      o is _Key && type == o.type && path == o.path && named == o.named;

  @override
  int get hashCode => hash3(type.hashCode, path.hashCode, named.hashCode);

  @override
  String toString() => '${element.name}';
}

class Dependency implements Comparable<Dependency> {
  const Dependency(
    this.named,
    this.type,
    this.dependencies,
    this.enclosingElement,
  );

  final DartType type;
  final Element enclosingElement;
  final List<Dependency> dependencies;
  final String? named;

  @override
  String toString() {
    return type.getName();
  }

  @override
  int compareTo(Dependency other) {
    return '${named ?? ''}_${type.getName()}'
        .compareTo('${other.named ?? ''}_${other.type.getName()}');
  }
}

abstract class ProviderSource {
  ProviderSource(this.type, this.annotations);

  final DartType type;

  Object get key {
    final j.QualifierAnnotation? qualifier = qualifierAnnotation;
    if (qualifier != null) {
      return '${qualifier.tag}_${createElementPath(type.element!)}/${type.getName()}';
    }

    return type;
  }

  j.QualifierAnnotation? get qualifierAnnotation {
    final Annotation? annotation = annotations
        .firstWhereOrNull((j.Annotation a) => a is j.QualifierAnnotation);
    return annotation is QualifierAnnotation ? annotation : null;
  }

  String? get tag => qualifierAnnotation?.tag;

  String get sourceString;

  final List<j.Annotation> annotations;
}

class ModuleSource extends ProviderSource {
  ModuleSource({
    required this.moduleClass,
    required DartType type,
    required List<j.Annotation> annotations,
    required this.method,
  }) : super(type, annotations);

  final ClassElement moduleClass;

  final j.Method method;

  @override
  String get sourceString => '${moduleClass.name}.${method.element.name}';
}

class BuildInstanceSource extends ProviderSource {
  BuildInstanceSource({
    required DartType type,
    required this.parameter,
    required List<j.Annotation> annotations,
  }) : super(type, annotations);

  final ParameterElement parameter;

  String get assignString {
    final j.QualifierAnnotation? qualifier = qualifierAnnotation;
    if (qualifier != null) {
      return '_${qualifier.tag}${parameter.type.getName()}';
    }

    return '_${uncapitalize(parameter.type.getName())}';
  }

  @override
  String get sourceString => '${parameter.type.getName()} ${parameter.name}';
}

class AnotherComponentSource extends ProviderSource {
  /// [element] method or property
  AnotherComponentSource({
    required DartType type,
    required this.element,
    required this.dependencyClass,
    required List<j.Annotation> annotations,
  })  : assert(element is MethodElement || element is PropertyAccessorElement),
        super(type, annotations);

  ///
  /// example: _appComponent
  ///
  final ClassElement dependencyClass;
  final Element element;

  ///
  /// example: _appComponent.getFoldersRouter()
  /// or for property
  /// example: _appComponent.foldersRouter
  ///
  String get assignString {
    final String base =
        '_${uncapitalize(dependencyClass.name)}.${element.name}';
    final String postfix = '${element is MethodElement ? '()' : ''}';
    return '$base$postfix';
  }

  @override
  String get sourceString => '${type.getName()}.${element.name}';
}
