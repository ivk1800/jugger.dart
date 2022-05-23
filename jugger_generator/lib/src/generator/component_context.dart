import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import '../errors_glossary.dart';
import '../jugger_error.dart';
import '../utils/dart_type_ext.dart';
import '../utils/utils.dart';
import 'graph_object_place.dart';
import 'tag.dart';
import 'visitors.dart';
import 'wrappers.dart';
import 'wrappers.dart' as j;

/// Class containing all information about the component, including the object
/// graph.
class ComponentContext {
  ComponentContext({
    required this.component,
    required this.componentBuilder,
  }) {
    for (final j.DependencyAnnotation dep in component.dependencies) {
      final Iterable<MethodElement> methods =
          dep.element.getComponentMethodsAccessors().map((e) => e.method);

      for (final MethodElement method in methods) {
        _registerSource(
          AnotherComponentSource(
            type: method.returnType,
            element: method,
            dependencyClass: dep.element,
            annotations: getAnnotations(method),
          ),
        );
      }

      final Iterable<PropertyAccessorElement> properties =
          dep.element.getComponentPropertiesAccessors().map((e) => e.property);

      for (final PropertyAccessorElement property in properties) {
        _registerSource(
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
        () => buildErrorMessage(
          error: JuggerErrorId.missing_component_builder,
          message:
              'Component ${component.element.name} depends on ${component.dependencies.map((j.DependencyAnnotation de) => de.element.name).join(',')}, but component builder is missing.',
        ),
      );
    }

    for (final j.ProvideMethod method in component.modulesProvideMethods) {
      final MethodElement element = method.element;

      _registerSource(
        ModuleSource(
          moduleClass: element.enclosingElement as ClassElement,
          type: element.returnType,
          method: method,
          annotations: getAnnotations(element),
        ),
      );
    }

    for (final ParameterElement parameter in componentBuilder?.parameters
            .map((ComponentBuilderParameter p) => p.parameter)
            .toList() ??
        <ParameterElement>[]) {
      _registerSource(
        ArgumentSource(
          parameter: parameter,
          type: parameter.type,
          componentBuilder: componentBuilder!,
          annotations: getAnnotations(parameter.enclosingElement!),
        ),
      );
    }

    for (final j.ProvideMethod method in component.modulesProvideMethods) {
      final MethodElement element = method.element;
      _registerGraphObject(element);
    }

    for (final MethodObjectAccessor method in component.methodsAccessors) {
      _registerGraphObject(method.method, GraphObjectPlace.component);
    }
    component.propertiesAccessors
        .map((e) => e.property)
        .forEach(_registerGraphObject);

    for (final j.MemberInjectorMethod method in component.memberInjectors) {
      final MethodElement element = method.element;

      for (final ParameterElement parameter in element.parameters) {
        final List<InjectedMember> members =
            parameter.type.element!.getInjectedMembers();

        for (final j.InjectedMember member in members) {
          _registerGraphObject(member.element);
        }
      }
    }
  }

  /// All objects of the component graph.
  final Map<_Key, GraphObject> _objectsGraph = HashMap<_Key, GraphObject>();
  final j.Component component;
  final j.ComponentBuilder? componentBuilder;

  /// All object sources of component. Does not contain duplicates.
  late final Set<ProviderSource> providerSources = HashSet<ProviderSource>(
    equals: _providesSourceEquals,
    hashCode: (ProviderSource p) {
      return Object.hash(p.type.hashCode, p.key.hashCode);
    },
  );

  /// All graph objects of the component.
  List<GraphObject> get objectsGraph => _objectsGraph.values.toList()
    // Sort so that the sequence is preserved with each code generation (for
    // test stability)
    ..sort((GraphObject a, GraphObject b) => a.compareTo(b));

  /// Queue to detect circular dependencies.
  final Queue<_Key> _objectsGraphQueue = Queue<_Key>();

  /// Registers a graph object with validation. Detects circular dependency.
  /// [element] an element that is a graph object. The element must be of a
  /// specific type that is supported. This is a method, parameter, field, and
  /// etc. The uniqueness of an object is determined using a qualifier and a
  /// type. If the type is already registered, the method simply returns it.
  /// [graphObjectPlace] the place of the graph object, the logic of registering
  /// the object depends on the value.
  GraphObject _registerGraphObject(
    Element element, [
    GraphObjectPlace? graphObjectPlace,
  ]) {
    final Tag? tag = element.getQualifierTag();

    final _Key key = _Key.of(element, tag);

    if (_objectsGraphQueue.contains(key)) {
      _objectsGraphQueue.addFirst(key);
      throw JuggerError(
        buildErrorMessage(
          error: JuggerErrorId.circular_dependency,
          message:
              'Found circular dependency! ${_objectsGraphQueue.toList().reversed.join('->')}',
        ),
      );
    }
    _objectsGraphQueue.addFirst(key);

    if (_objectsGraph.containsKey(key)) {
      _objectsGraphQueue.removeFirst();
      return _objectsGraph[key]!;
    }

    if (element is MethodElement) {
      if (graphObjectPlace == GraphObjectPlace.component) {
        final ConstructorElement? injectedConstructor =
            element.returnType.getInjectedConstructorOrNull();

        final GraphObject graphObject = GraphObject(
          tag,
          element.returnType,
          injectedConstructor != null
              ? _registerConstructorObjects(injectedConstructor)
              : <GraphObject>[],
        );
        _registerAndValidateGraphObject(key, graphObject);
        _objectsGraphQueue.removeFirst();
        return graphObject;
      }

      final GraphObject graphObject = GraphObject(
        tag,
        element.returnType,
        _registerMethodObjects(element),
      );
      _registerAndValidateGraphObject(key, graphObject);
      _objectsGraphQueue.removeFirst();
      return graphObject;
    } else if (element is VariableElement) {
      _objectsGraphQueue.removeFirst();
      return _registerVariableElementGraphObject(element);
    } else if (element is PropertyAccessorElement) {
      final ConstructorElement? injectedConstructor =
          element.returnType.getInjectedConstructorOrNull();
      final GraphObject graphObject = GraphObject(
        tag,
        element.returnType,
        injectedConstructor != null
            ? _registerConstructorObjects(injectedConstructor)
            : <GraphObject>[],
      );
      _registerAndValidateGraphObject(key, graphObject);
      _objectsGraphQueue.removeFirst();
      return graphObject;
    }

    throw JuggerError(
      buildUnexpectedErrorMessage(
        message:
            'Field ${element.name} unsupported type [${element.runtimeType}]',
      ),
    );
  }

  /// The method checks the type for a supported one and registers the object.
  void _registerAndValidateGraphObject(_Key key, GraphObject object) {
    key.type.checkUnsupportedType();

    if (object.type.isProvider) {
      check(
        object.dependencies.isEmpty,
        () => buildUnexpectedErrorMessage(
          message: 'provider with dependencies!',
        ),
      );
      final DartType providerType = object.type.getSingleTypeArgument;

      List<GraphObject> objects = object.dependencies;

      if (providerType.hasInjectedConstructor()) {
        objects = _registerConstructorObjects(
          providerType.getRequiredInjectedConstructor(),
        );
      }

      _objectsGraph[key] = GraphObject(
        object.tag,
        providerType,
        objects,
      );
    } else {
      _objectsGraph[key] = object;
    }
  }

  /// Registers the variable as a graph object if it has not been registered
  /// before.
  GraphObject _registerVariableElementGraphObject(VariableElement element) {
    final Tag? tag = element.getQualifierTag();

    final _Key key = _Key.of(element, tag);

    final ConstructorElement? injectedConstructor =
        element.type.getInjectedConstructorOrNull();

    if (injectedConstructor == null) {
      final GraphObject graphObject = GraphObject(
        tag,
        element.type,
        <GraphObject>[],
      );
      _registerAndValidateGraphObject(key, graphObject);
      return graphObject;
    }

    final List<GraphObject> objects =
        _registerConstructorObjects(injectedConstructor);

    final GraphObject object = GraphObject(
      tag,
      element.type,
      objects,
    );
    _registerAndValidateGraphObject(key, object);
    return object;
  }

  /// Registers the all parameters of constructor as a graph object if it has not
  /// been registered before.
  List<GraphObject> _registerConstructorObjects(ConstructorElement element) {
    final List<GraphObject> objects =
        element.parameters.map((ParameterElement parameter) {
      _registerParamObjectIfNeed(parameter);
      return _registerGraphObject(parameter);
    }).toList();

    return objects;
  }

  /// Registers the all parameters of method as a graph object if it has not
  /// been registered before.
  List<GraphObject> _registerMethodObjects(MethodElement element) {
    final List<GraphObject> objects =
        element.parameters.map((ParameterElement parameter) {
      _registerParamObjectIfNeed(parameter);
      return _registerGraphObject(parameter);
    }).toList();

    return objects;
  }

  /// Registers the parameter as a graph object if it has not been registered
  /// before.
  void _registerParamObjectIfNeed(ParameterElement parameter) {
    final j.ProvideMethod? provideMethod = findProvideMethod(
      type: parameter.type,
      tag: parameter.getQualifierTag(),
    );

    if (provideMethod != null) {
      _registerGraphObject(provideMethod.element);
    }
  }

  /// Find the method of the component that provided the given type with tag.
  j.ProvideMethod? findProvideMethod({
    required DartType type,
    required Tag? tag,
  }) {
    return component.modulesProvideMethods
        .firstWhereOrNull((j.ProvideMethod method) {
      return method.element.returnType == type && method.tag == tag;
    });
  }

  /// Method returns type source by type and tag.
  ProviderSource? findProvider(DartType type, [Tag? tag]) {
    return providerSources.firstWhereOrNull((ProviderSource source) {
      return source.type == type && source.tag == tag;
    });
  }

  /// Helper function for equals sources. Equals and hash code is not overridden
  /// in the source, so you need to use this function.
  bool _providesSourceEquals(ProviderSource p1, ProviderSource p2) {
    return p1.type == p2.type && p1.key == p2.key;
  }

  /// Register the source, but if a source with this type is already registered,
  /// throws an error.
  void _registerSource(ProviderSource source) {
    check(providerSources.add(source), () {
      final List<ProviderSource> sources = <ProviderSource>[
        providerSources
            .firstWhere((ProviderSource s) => _providesSourceEquals(s, source)),
        source
      ];

      final String places = sources
          .map((ProviderSource source) => source.sourceString)
          .join(', ');
      final String message = '${source.type} provided multiple times: $places';
      return buildErrorMessage(
        error: JuggerErrorId.multiple_providers_for_type,
        message: message,
      );
    });
  }
}

/// Identifier of type source. Serves to build a dependency graph.
class _Key {
  _Key({
    required this.tag,
    required this.type,
    required Element element,
  }) : _element = element;

  factory _Key.of(Element element, Tag? tag) {
    if (element is MethodElement) {
      return _Key(
        tag: tag,
        element: element,
        type: element.returnType,
      );
    } else if (element is VariableElement) {
      if (element.type.isProvider) {
        return _Key(
          tag: tag,
          element: element,
          type: element.type.getSingleTypeArgument,
        );
      }

      return _Key(
        tag: tag,
        element: element,
        type: element.type,
      );
    } else if (element is PropertyAccessorElement) {
      return _Key(
        tag: tag,
        element: element,
        type: element.returnType,
      );
    }

    throw JuggerError(
      'field [${element.name}] unsupported type [${element.runtimeType}]',
    );
  }

  /// An element that provides an object of type.
  final Element _element;

  /// The type to which the key belongs.
  final DartType type;

  /// Tag associated with the type.
  final Tag? tag;

  @override
  bool operator ==(dynamic o) => o is _Key && type == o.type && tag == o.tag;

  @override
  int get hashCode => hash2(type.hashCode, tag.hashCode);

  @override
  String toString() => '${_element.name}';
}

/// Object of graph.
class GraphObject implements Comparable<GraphObject> {
  const GraphObject(
    this.tag,
    this.type,
    this.dependencies,
  );

  /// Object type.
  final DartType type;

  /// Dependencies of object. These dependencies may vary depending on the source
  /// that this object provides. If the object is provided by a module method,
  /// the dependencies will be the method arguments. If the Object is provided
  /// by an injectable constructor, the dependencies will be the constructor
  /// arguments. Etc.
  final List<GraphObject> dependencies;

  /// Object tag, the tag is constructed from a type and a qualifier.
  final Tag? tag;

  @override
  String toString() {
    return type.getName();
  }

  @override
  int compareTo(GraphObject other) {
    return '${tag ?? ''}_${type.getName()}'
        .compareTo('${other.tag ?? ''}_${other.type.getName()}');
  }
}

/// Base type of graph object source.
abstract class ProviderSource {
  ProviderSource(this.type, this.annotations);

  /// The type that the source provides.
  final DartType type;

  /// All source annotations, see implementations of this interface for details.
  final List<j.Annotation> annotations;

  /// A unique key of source. Qualifier and type will be combined.
  /// Should be used to identify the source.
  Object get key {
    final j.QualifierAnnotation? qualifier = qualifierAnnotation;
    if (qualifier != null) {
      return '${qualifier.tag}_${createElementPath(type.element!)}/${type.getName()}';
    }

    return type;
  }

  /// Source qualifier. This is a custom qualifier or a named annotation.
  j.QualifierAnnotation? get qualifierAnnotation {
    final Annotation? annotation = annotations
        .firstWhereOrNull((j.Annotation a) => a is j.QualifierAnnotation);
    return annotation is QualifierAnnotation ? annotation : null;
  }

  /// Source tag. This is a custom qualifier or a named annotation. Can be used
  /// to find a provider. Multiple types can have the same tag, so it does not
  /// guarantee the uniqueness of the source, you need to use the [key] for this
  Tag? get tag => qualifierAnnotation?.tag;

  /// A string indicating the location of the source. Should be used when a code
  /// generation error occurs.
  String get sourceString;
}

/// Type source is module.
class ModuleSource extends ProviderSource {
  ModuleSource({
    required this.moduleClass,
    required DartType type,
    required List<j.Annotation> annotations,
    required this.method,
  }) : super(type, annotations);

  /// The module in which the method is located.
  final ClassElement moduleClass;

  /// A method that provided a dependency. Static or abstract.
  /// ```
  /// @module
  /// abstract class Module {
  ///   @provides
  ///   static int provideInt() => 0; // <---
  /// }
  /// ```
  final j.ProvideMethod method;

  @override
  String get sourceString => '${moduleClass.name}.${method.element.name}';
}

/// Type source is argument of component builder.
class ArgumentSource extends ProviderSource {
  ArgumentSource({
    required DartType type,
    required this.parameter,
    required j.ComponentBuilder componentBuilder,
    required List<j.Annotation> annotations,
  })  : _componentBuilder = componentBuilder,
        super(type, annotations);

  /// Parameter of the method of component builder.
  /// ```
  /// @componentBuilder
  /// abstract class MyComponentBuilder {
  ///   MyComponentBuilder setSting(
  ///     String s, // <---
  ///   );
  ///
  ///   AppComponent build();
  /// }
  /// ````
  final ParameterElement parameter;

  /// Component builder in which the method is located.
  final j.ComponentBuilder _componentBuilder;

  @override
  String get sourceString {
    return '${_componentBuilder.element.name}.${parameter.enclosingElement?.name}';
  }
}

/// Type source is a component.
class AnotherComponentSource extends ProviderSource {
  AnotherComponentSource({
    required DartType type,
    required this.element,
    required ClassElement dependencyClass,
    required List<j.Annotation> annotations,
  })  : _dependencyClass = dependencyClass,
        assert(element is MethodElement || element is PropertyAccessorElement),
        super(type, annotations);

  /// The component class that is used as a dependency.
  final ClassElement _dependencyClass;

  /// Method or property which provides an object instance.
  /// ```
  /// @Component()
  /// abstract class AppComponent {
  ///   String get string; //  <---
  ///   String getString(); // <---
  /// }
  /// ```
  final Element element;

  ///
  /// example: _appComponent.getFoldersRouter()
  /// or for property
  /// example: _appComponent.foldersRouter
  ///
  String get assignString {
    final String base =
        '_${uncapitalize(_dependencyClass.name)}.${element.name}';
    final String postfix = element is MethodElement ? '()' : '';
    return '$base$postfix';
  }

  @override
  String get sourceString => '${_dependencyClass.name}.${element.name}';
}
