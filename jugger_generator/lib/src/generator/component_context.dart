import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import '../errors_glossary.dart';
import '../jugger_error.dart';
import '../utils/annotation_ext.dart';
import '../utils/component_methods_ext.dart';
import '../utils/dart_type_ext.dart';
import '../utils/element_annotation_ext.dart';
import '../utils/element_ext.dart';
import '../utils/source_ext.dart';
import '../utils/utils.dart';
import 'entry_points.dart';
import 'graph_object_place.dart';
import 'multibindings/multibindings_group.dart';
import 'multibindings/multibindings_info.dart';
import 'multibindings/multibindings_manager.dart';
import 'subcomponent/parent_component_provider.dart';
import 'tag.dart';
import 'visitors.dart';
import 'wrappers.dart' as j;

/// Class containing all information about the component, including the object
/// graph.
class ComponentContext {
  ComponentContext({
    required this.component,
    required this.componentBuilder,
    required this.parentComponentProvider,
  }) {
    _validateParentScopes();
    final ParentComponentProvider? parent = parentComponentProvider;
    if (parent != null) {
      _registerParentGraph(parent.fullInfo);
    }

    for (final j.DependencyAnnotation dep in component.dependencies) {
      final List<j.ComponentMethod> componentMembers =
          dep.element.getComponentMembers();
      final Iterable<MethodElement> methods = componentMembers
          .getComponentMethodsAccessors()
          .map((j.MethodObjectAccessor e) => e.method);

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

      final Iterable<PropertyAccessorElement> properties = componentMembers
          .getComponentPropertiesAccessors()
          .map((j.PropertyObjectAccessor e) => e.property);

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
          multibindingsInfo: element.getMultibindingsInfo(),
        ),
      );
    }

    for (final ParameterElement parameter in componentBuilder?.parameters
            .map((j.ComponentBuilderParameter p) => p.parameter)
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
      _registerGraphObject(method.element);
    }

    for (final j.MethodObjectAccessor method in component.methodsAccessors) {
      _registerGraphObject(method.method, GraphObjectPlace.component);
    }
    component.propertiesAccessors
        .map((j.PropertyObjectAccessor e) => e.property)
        .forEach(_registerGraphObject);

    for (final j.MemberInjectorMethod method in component.memberInjectors) {
      final MethodElement element = method.element;

      for (final ParameterElement parameter in element.parameters) {
        final List<j.InjectedMember> members =
            parameter.type.element!.getInjectedMembers();

        for (final j.InjectedMember member in members) {
          _registerGraphObject(member.element);
        }
      }
    }

    final List<MultibindingsGroup> bindingsInfo =
        multibindingsManager.getBindingsInfo();

    for (final MultibindingsGroup info in bindingsInfo) {
      _registerSource(
        MultibindingsSource(
          type: info.graphObject.type,
          multibindingsGroup: info,
          annotations: info.annotations,
        ),
      );
    }

    _registerAdditionalSources();
    _checkMissingProviders();
  }

  /// All objects of the component graph.
  final Map<_Key, GraphObject> _graphObjects = HashMap<_Key, GraphObject>();

  final j.Component component;
  final j.ComponentBuilder? componentBuilder;
  final ParentComponentProvider? parentComponentProvider;

  /// All object sources of component. Does not contain duplicates.
  late final Set<ProviderSource> providerSources = HashSet<ProviderSource>(
    equals: _providesSourceEquals,
    hashCode: (ProviderSource p) {
      return Object.hash(
        p.type.hashCode,
        p.key.hashCode,
        p.multibindingsInfo?.hashCode,
      );
    },
  );

  late final MultibindingsManager multibindingsManager =
      MultibindingsManager(this);

  /// All graph objects of the component.
  List<GraphObject> get graphObjects => _graphObjects.values
      .toList()
      // Sort so that the sequence is preserved with each code generation (for
      // test stability)
      .sorted((GraphObject a, GraphObject b) => a.compareTo(b));

  /// Queue to detect circular dependencies.
  final Queue<_Key> _graphObjectsQueue = Queue<_Key>();

  late final List<ParentComponentInfo> _parentInfo = () {
    final ParentComponentProvider? parent = parentComponentProvider;
    return parent?.fullInfo ?? <ParentComponentInfo>[];
  }();

  late final ParentComponentInfo _selfAsParentInfo = ParentComponentInfo(
    sources: providerSources.where((ProviderSource source) {
      return source is! MultibindingsSource &&
          // It makes no sense to pass this type, since the original object is
          // in the parent
          source is! ParentComponentSource &&
          source is! ParentMultibindingsItemSource;
    }).toList(growable: false),
    componentName: component.element.name,
    // TODO: filter objets from parents
    graphObjects: Map<_Key, GraphObject>.from(_graphObjects),
    depth: _parentInfo.length,
    scope: component.scope,
  );

  late final List<ParentComponentInfo> fullParentInfoWithSelf = () {
    return <ParentComponentInfo>[..._parentInfo, _selfAsParentInfo];
  }();

  void _registerParentGraph(List<ParentComponentInfo> fullInfo) {
    for (final ParentComponentInfo parentInfo in fullInfo) {
      _registerParentSources(
        sources: parentInfo.sources,
        componentName: parentInfo.componentName,
        // yeah depth is an id, it is unique for each parent
        parentId: parentInfo.depth,
      );
      _graphObjects.addAll(parentInfo.graphObjects);
    }
  }

  int getDepthOfParent({required int parentId}) {
    // yeah id is an depth, just match reversed index for calculating depth
    return _parentInfo.length - parentId;
  }

  void _registerParentSources({
    required List<ProviderSource> sources,
    required String componentName,
    required int parentId,
  }) {
    for (final ProviderSource parentSource in sources) {
      checkUnexpected(
        parentSource is! MultibindingsSource,
        () =>
            "$MultibindingsSource can not be return from $ParentComponentProvider",
      );
      if (parentSource.isMultibindings) {
        _registerSource(
          ParentMultibindingsItemSource(
            originalSource: parentSource,
            componentName: componentName,
          ),
        );
      } else {
        _registerSource(
          ParentComponentSource(
            originalSource: parentSource,
            componentName: componentName,
            id: parentId,
          ),
        );
      }
    }
  }

  void _validateParentScopes() {
    if (parentComponentProvider == null) {
      return;
    }

    final List<ParentComponentInfo> parentInfo = _parentInfo;
    final Object? selfScope = component.scope;

    if (selfScope != null) {
      final Iterable<ParentComponentInfo> scopedParents =
          parentInfo.where((ParentComponentInfo p) => p.scope != null);
      check(
        scopedParents.every((ParentComponentInfo p) => p.scope != selfScope),
        () {
          final String info = '${component.element.name}: $selfScope\n'
              '${scopedParents.map((ParentComponentInfo p) {
            return '${p.componentName}: ${p.scope ?? 'unscoped'}';
          }).join('\n')}';

          return buildErrorMessage(
            error: JuggerErrorId.invalid_scope,
            message: 'The scope of the component must be different from the '
                'scope of the parent or should there be no scope.\n$info',
          );
        },
      );
    }
  }

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

    if (_graphObjectsQueue.contains(key)) {
      _graphObjectsQueue.addFirst(key);
      throw JuggerError(
        buildErrorMessage(
          error: JuggerErrorId.circular_dependency,
          message:
              'Found circular dependency! ${_graphObjectsQueue.toList().reversed.join('->')}',
        ),
      );
    }
    _graphObjectsQueue.addFirst(key);

    if (_graphObjects.containsKey(key)) {
      _graphObjectsQueue.removeFirst();
      return _graphObjects[key]!;
    }

    if (element is MethodElement) {
      if (graphObjectPlace == GraphObjectPlace.component) {
        final GraphObject graphObject = GraphObject(
          tag: tag,
          type: element.returnType,
          dependencies: _registerConstructorObjectsIfNeeded(
            type: element.returnType,
            or: const <GraphObject>[],
          ),
        );
        _registerAndValidateGraphObject(key, graphObject);
        _graphObjectsQueue.removeFirst();
        return graphObject;
      }

      final GraphObject graphObject = GraphObject(
        tag: tag,
        type: element.returnType,
        dependencies: _registerMethodObjects(element),
        multibindingsInfo: element.getMultibindingsInfo(),
      );
      _registerAndValidateGraphObject(key, graphObject);
      _graphObjectsQueue.removeFirst();
      return graphObject;
    } else if (element is VariableElement) {
      _graphObjectsQueue.removeFirst();
      return _registerVariableElementGraphObject(element);
    } else if (element is PropertyAccessorElement) {
      final GraphObject graphObject = GraphObject(
        tag: tag,
        type: element.returnType,
        dependencies: _registerConstructorObjectsIfNeeded(
          type: element.returnType,
          or: const <GraphObject>[],
        ),
      );
      _registerAndValidateGraphObject(key, graphObject);
      _graphObjectsQueue.removeFirst();
      return graphObject;
    }

    throw UnexpectedJuggerError(
      'Field ${element.name} unsupported type [${element.runtimeType}]',
    );
  }

  List<GraphObject> _registerConstructorObjectsIfNeeded({
    required DartType type,
    required List<GraphObject> or,
  }) {
    if (type.element is EnumElement) {
      return or;
    }

    final ConstructorElement? injectedConstructor =
        type.getInjectedConstructorOrNull();

    return injectedConstructor != null
        ? _registerConstructorObjects(injectedConstructor)
        : or;
  }

  /// The method checks the type for a supported one and registers the object.
  void _registerAndValidateGraphObject(_Key key, GraphObject object) {
    key.type.checkUnsupportedType();

    if (object.type.isValueProvider) {
      check(
        object.dependencies.isEmpty,
        () => buildUnexpectedErrorMessage(
          message: 'provider with dependencies!',
        ),
      );
      final DartType providerType = object.type.getSingleTypeArgument;

      _graphObjects[key] = GraphObject(
        tag: object.tag,
        type: providerType,
        dependencies: _registerConstructorObjectsIfNeeded(
          type: providerType,
          or: object.dependencies,
        ),
      );
    } else {
      _graphObjects[key] = object;
    }
  }

  /// Registers the variable as a graph object if it has not been registered
  /// before.
  GraphObject _registerVariableElementGraphObject(VariableElement element) {
    final Tag? tag = element.getQualifierTag();

    final _Key key = _Key.of(element, tag);

    final GraphObject object = GraphObject(
      tag: tag,
      type: element.type,
      dependencies: _registerConstructorObjectsIfNeeded(
        type: element.type,
        or: const <GraphObject>[],
      ),
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
      return method.element.returnType == type &&
          method.tag == tag &&
          !method.element.isMultibindings();
    });
  }

  /// Returns type source by type and tag or null if not found.
  ProviderSource? findProviderOrNull(
    DartType type, [
    Tag? tag,
    MultibindingsInfo? multibindingsInfo,
  ]) {
    return providerSources.firstWhereOrNull((ProviderSource source) {
      return source.type == type &&
          source.tag == tag &&
          source.multibindingsInfo == multibindingsInfo;
    });
  }

  /// Returns type source by type and tag or throws error if not found.
  ProviderSource findProvider(
    DartType type, [
    Tag? tag,
    MultibindingsInfo? multibindingsInfo,
  ]) {
    final ProviderSource? source = findProviderOrNull(
      type,
      tag,
      multibindingsInfo,
    );
    if (source == null) {
      throw ProviderNotFoundError(
        type: type,
        tag: tag,
        message: buildProviderNotFoundMessage(type, tag),
      );
    }
    return source;
  }

  GraphObject findGraphObject({
    required DartType type,
    required Tag? tag,
    required MultibindingsInfo? multibindingsInfo,
  }) {
    final GraphObject? object =
        graphObjects.firstWhereOrNull((GraphObject element) {
      return element.tag == tag &&
          element.type == type &&
          element.multibindingsInfo == multibindingsInfo;
    });
    if (object == null) {
      throw UnexpectedJuggerError('Unable find graph object.');
    }

    return object;
  }

  /// Helper function for equals sources. Equals and hash code is not overridden
  /// in the source, so you need to use this function.
  bool _providesSourceEquals(ProviderSource p1, ProviderSource p2) =>
      p1.type == p2.type &&
      p1.key == p2.key &&
      p1.multibindingsInfo == p2.multibindingsInfo;

  /// Register the source, but if a source with this type is already registered,
  /// throws an error.
  void _registerSource(ProviderSource source) {
    if (source.isMultibindings) {
      multibindingsManager.handleSource(source);
    }
    _registerSourceOf(providerSources, source);
  }

  void _registerSourceOf(
    Set<ProviderSource> providerSources,
    ProviderSource source,
  ) {
    _validateSource(source);
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

  void _validateSource(ProviderSource source) {
    final j.ScopeAnnotation? componentScope = component.scope;
    if (source.scope == null || source is ParentMultibindingsItemSource) {
      return;
    }

    check(
      componentScope == source.scope ||
          (source is ParentComponentSource && componentScope != source.scope),
      () {
        final StringBuffer messageBuilder = StringBuffer()
          ..write(component.element.name)
          ..write(' ');

        if (componentScope != null) {
          messageBuilder.write('(scoped $componentScope)');
        } else {
          messageBuilder.write('(unscoped)');
        }
        messageBuilder
          ..write(' ')
          ..write('may not use scoped bindings: ')
          ..write('${source.scope}(${source.sourceString})');

        return buildErrorMessage(
          error: JuggerErrorId.invalid_scope,
          message: messageBuilder.toString(),
        );
      },
    );
  }

  /// Iterates over all graph objects and registers sources for types with
  /// an injected constructor and 'this' component source.
  void _registerAdditionalSources() {
    final List<ProviderNotFoundError> providerNotFoundErrors =
        <ProviderNotFoundError>[];

    final Map<_Key, GraphObject> graphObjects = _graphObjects;

    for (final GraphObject graphObject in graphObjects.values) {
      final DartType type = graphObject.type;

      if (type.element is EnumElement) {
        continue;
      }

      if (type == component.element.thisType) {
        _registerSource(
          ThisComponentSource(
            type: type,
            annotations: getAnnotations(type.element!),
          ),
        );
        continue;
      }

      final Tag? tag = graphObject.tag;
      final ProviderSource? source = findProviderOrNull(
        type,
        tag,
        graphObject.multibindingsInfo,
      );

      if (source == null && tag != null) {
        providerNotFoundErrors.add(
          ProviderNotFoundError(
            type: type,
            tag: tag,
            message: buildProviderNotFoundMessage(type, tag),
          ),
        );
        continue;
      } else if (source != null || isCore(type.element!)) {
        continue;
      }
      try {
        final ConstructorElement injectedConstructor =
            type.getRequiredInjectedConstructor();
        _registerSource(
          InjectedConstructorSource(
            type: type,
            element: injectedConstructor,
            annotations: getAnnotations(type.element!),
          ),
        );
      }
      // ignore: avoid_catching_errors
      on ProviderNotFoundError catch (e) {
        providerNotFoundErrors.add(e);
      }
    }

    _checkForThrows(providerNotFoundErrors);
  }

  /// Iterates over all graph objects and check missing provider for types.
  void _checkMissingProviders() {
    final List<ProviderNotFoundError> providerNotFoundErrors =
        <ProviderNotFoundError>[];

    for (final GraphObject graphObject in graphObjects) {
      final ProviderSource? provider = findProviderOrNull(
        graphObject.type,
        graphObject.tag,
        graphObject.multibindingsInfo,
      );

      if (provider == null) {
        providerNotFoundErrors.add(
          ProviderNotFoundError(
            type: graphObject.type,
            tag: graphObject.tag,
            message:
                buildProviderNotFoundMessage(graphObject.type, graphObject.tag),
          ),
        );
      }
    }

    _checkForThrows(providerNotFoundErrors);
  }

  void _checkForThrows(List<ProviderNotFoundError> providerNotFoundErrors) {
    if (providerNotFoundErrors.isNotEmpty) {
      throw JuggerError(
        providerNotFoundErrors.map((ProviderNotFoundError error) {
          final String? entryPoints = findEntryPointsOf(
            error.type,
            error.tag,
            graphObjects,
            findProvider,
          );
          if (entryPoints == null) {
            return error.message;
          }

          return '${error.message}\nThe following entry points depend on ${error.type.getName()}:\n$entryPoints';
        }).join('\n'),
      );
    }
  }
}

/// Identifier of type source. Serves to build a dependency graph.
class _Key {
  _Key({
    required this.tag,
    required this.type,
    required Element element,
    this.multibindingsInfo,
  }) : _element = element;

  factory _Key.of(Element element, Tag? tag) {
    if (element is MethodElement) {
      return _Key(
        tag: tag,
        element: element,
        type: element.returnType,
        multibindingsInfo: element.getMultibindingsInfo(),
      );
    } else if (element is VariableElement) {
      if (element.type.isValueProvider) {
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

    throw UnexpectedJuggerError(
      'Field [${element.name}] unsupported type [${element.runtimeType}]',
    );
  }

  /// An element that provides an object of type.
  final Element _element;

  final MultibindingsInfo? multibindingsInfo;

  /// The type to which the key belongs.
  final DartType type;

  /// Tag associated with the type.
  final Tag? tag;

  @override
  bool operator ==(Object o) =>
      o is _Key &&
      type == o.type &&
      tag == o.tag &&
      multibindingsInfo == o.multibindingsInfo;

  @override
  int get hashCode => hash3(type.hashCode, tag.hashCode, multibindingsInfo);

  @override
  String toString() => '${_element.name}';
}

/// Object of graph.
class GraphObject implements Comparable<GraphObject> {
  const GraphObject({
    required this.tag,
    required this.type,
    required this.dependencies,
    this.multibindingsInfo,
  });

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

  final MultibindingsInfo? multibindingsInfo;

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
  ProviderSource({
    required this.type,
    required this.annotations,
    this.multibindingsInfo,
  });

  /// The type that the source provides.
  final DartType type;

  /// All source annotations, see implementations of this interface for details.
  final List<j.Annotation> annotations;

  final MultibindingsInfo? multibindingsInfo;

  late final j.ScopeAnnotation? scope = annotations.getAnnotationOrNull();

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
    final j.Annotation? annotation = annotations
        .firstWhereOrNull((j.Annotation a) => a is j.QualifierAnnotation);
    return annotation is j.QualifierAnnotation ? annotation : null;
  }

  /// Source tag. This is a custom qualifier or a named annotation. Can be used
  /// to find a provider. Multiple types can have the same tag, so it does not
  /// guarantee the uniqueness of the source, you need to use the [key] for this
  Tag? get tag => qualifierAnnotation?.tag;

  /// A string indicating the location of the source. Should be used when a code
  /// generation error occurs.
  String get sourceString;
}

abstract class MultibindingsElementProvider {
  MethodElement get element;
}

/// Type source is module.
class ModuleSource extends ProviderSource
    implements MultibindingsElementProvider {
  ModuleSource({
    required this.moduleClass,
    required DartType type,
    required List<j.Annotation> annotations,
    required this.method,
    required MultibindingsInfo? multibindingsInfo,
  }) : super(
          type: type,
          annotations: annotations,
          multibindingsInfo: multibindingsInfo,
        );

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

  @override
  late final Object key = () {
    if (annotations
        .whereType<j.MultibindingsGroupAnnotation>()
        .toList(growable: false)
        .isNotEmpty) {
      return '${super.key}_${method.hashCode}';
    }
    return super.key;
  }();

  @override
  MethodElement get element => method.element;
}

/// Type source is argument of component builder.
class ArgumentSource extends ProviderSource {
  ArgumentSource({
    required DartType type,
    required this.parameter,
    required j.ComponentBuilder componentBuilder,
    required List<j.Annotation> annotations,
  })  : _componentBuilder = componentBuilder,
        super(
          type: type,
          annotations: annotations,
        );

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
        super(
          type: type,
          annotations: annotations,
        );

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

class ParentMultibindingsItemSource extends ProviderSource
    implements MultibindingsElementProvider {
  ParentMultibindingsItemSource({
    required this.originalSource,
    required this.componentName,
  })  : assert(originalSource is MultibindingsElementProvider),
        _originalMultibindingsElementProvider =
            originalSource as MultibindingsElementProvider,
        super(
          type: originalSource.type,
          annotations: originalSource.annotations,
          multibindingsInfo: originalSource.multibindingsInfo,
        );

  final ProviderSource originalSource;
  final String componentName;
  final MultibindingsElementProvider _originalMultibindingsElementProvider;

  @override
  String get sourceString => '${originalSource.sourceString}($componentName)';

  @override
  MethodElement get element => _originalMultibindingsElementProvider.element;
}

class ParentComponentSource extends ProviderSource {
  ParentComponentSource({
    required this.originalSource,
    required this.componentName,
    required this.id,
  }) : super(
          type: originalSource.type,
          annotations: originalSource.annotations,
          multibindingsInfo: originalSource.multibindingsInfo,
        );

  final ProviderSource originalSource;
  final String componentName;
  final int id;

  @override
  String get sourceString => '${originalSource.sourceString}($componentName)';
}

class InjectedConstructorSource extends ProviderSource {
  InjectedConstructorSource({
    required DartType type,
    required this.element,
    required List<j.Annotation> annotations,
  }) : super(
          type: type,
          annotations: annotations,
        );

  final ConstructorElement element;

  @override
  String get sourceString => 'constructor of ${element.enclosingElement.name}';
}

/// The source of the current component. It means if the current component
/// is required as a dependency.
/// Example:
/// ```
/// @provides
///  static String provideString(AppComponent appComponent)
/// ```
class ThisComponentSource extends ProviderSource {
  ThisComponentSource({
    required DartType type,
    required List<j.Annotation> annotations,
  }) : super(
          type: type,
          annotations: annotations,
        );

  @override
  String get sourceString => 'this';
}

class MultibindingsSource extends ProviderSource {
  MultibindingsSource({
    required DartType type,
    required this.multibindingsGroup,
    required List<j.Annotation> annotations,
  }) : super(
          type: type,
          annotations: annotations,
        );

  final MultibindingsGroup multibindingsGroup;

  @override
  String get sourceString =>
      'Multibinding of: ${multibindingsGroup.graphObject.type.getName()}';
}

class ParentComponentInfo {
  ParentComponentInfo({
    required this.graphObjects,
    required this.componentName,
    required this.sources,
    required this.depth,
    required this.scope,
  });

  final Map<_Key, GraphObject> graphObjects;
  final List<ProviderSource> sources;
  final String componentName;
  final Object? scope;
  final int depth;
}

extension _ElementExt on Element {
  bool isMultibindings() {
    return getAnnotations(this).any(
      (j.Annotation annotation) =>
          annotation is j.IntoSetAnnotation ||
          annotation is j.IntoMapAnnotation,
    );
  }
}

extension _MethodElementExt on MethodElement {
  MultibindingsInfo? getMultibindingsInfo() {
    final j.MultibindingsGroupAnnotation? annotation =
        getMultibindingsGroupAnnotationOrNull();

    if (annotation == null) {
      return null;
    }

    final String methodPath = '${(enclosingElement as ClassElement).name}.'
        '$name';

    if (annotation is j.IntoSetAnnotation ||
        annotation is j.IntoMapAnnotation) {
      return MultibindingsInfo(
        tag: getQualifierTag(),
        methodPath: methodPath,
      );
    } else {
      throw UnexpectedJuggerError(
        'Unknown Multibinding annotation $annotation.',
      );
    }
  }
}
