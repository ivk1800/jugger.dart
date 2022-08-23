/// Annotates an abstract class for which a dependency-injected implementation
/// is to be generated from a set of modules.
class Component {
  const factory Component({
    List<Type> modules,
    List<Type> dependencies,
    Type? builder,
  }) = Component._;

  const Component._({
    this.modules = const <Type>[],
    this.dependencies = const <Type>[],
    this.builder = null,
  });

  final List<Type> modules;
  final List<Type> dependencies;

  /// Builder for this component.
  final Type? builder;
}

/// Identifies qualifier annotations.
class Qualifier {
  const Qualifier._();
}

/// Annotates a class that contributes to the object graph.
class Module {
  const factory Module({List<Type> includes}) = Module._;

  const Module._({this.includes = const <Type>[]});

  final List<Type> includes;
}

/// Identifies scope annotations. By default, if no scope annotation is present,
/// the injector creates an instance, uses the instance for one injection, and
/// then forgets it. If a scope annotation is present, the injector retain the
/// instance for reuse in a later injection.
class Scope {
  const Scope._();
}

const Scope scope = Scope._();

/// Identifies a type that the injector only instantiates once.
@scope
class Singleton {
  const Singleton._();
}

/// Annotates methods of a module to create a provider method binding.
class Provides {
  const Provides._();
}

/// Identifies injectable constructors, methods, and fields.
class Inject {
  const factory Inject() = Inject._;

  const Inject._();
}

/// Annotates abstract methods of a module that delegate bindings.
class Binds {
  const Binds._();
}

const ComponentBuilder componentBuilder = ComponentBuilder._();

/// Annotates a class that contributes to create a component.
class ComponentBuilder {
  const ComponentBuilder._();
}

/// String-based qualifier.
@qualifier
class Named {
  const factory Named(String name) = Named._;

  const Named._(this.name);

  final String name;
}

/// A handle to a non lazily-computed value. Computed on create component.
class NonLazy {
  const factory NonLazy() = NonLazy._;

  const NonLazy._();
}

const NonLazy nonLazy = NonLazy._();

const Provides provides = Provides._();

const Module module = Module._();

const Singleton singleton = Singleton._();

const Inject inject = Inject._();

const Binds binds = Binds._();

const Qualifier qualifier = Qualifier._();

// region disposal

/// Identifies that this is a graph object disposer.
class DisposalHandler {
  const DisposalHandler._();
}

const DisposalHandler disposalHandler = DisposalHandler._();

/// Identifies that the graph object can be disposed after the life of the
/// component ends. Disposable object has two disposal strategies:
/// 1) if the object has a dispose method and the jugger only needs to call it;
/// 2) if the object has a custom disposal and for this need to declare a
/// handle method for disposal.
class Disposable {
  const factory Disposable({
    required DisposalStrategy strategy,
  }) = Disposable._;

  const Disposable._({required this.strategy});

  final DisposalStrategy strategy;
}

const Disposable disposable = Disposable._(strategy: DisposalStrategy.auto);

enum DisposalStrategy {
  /// The jugger will try to find a method that matches:
  /// Future<void> dispose() or void dispose()
  auto,

  /// To dispose of an object, need to declare the handle method in the module
  /// with an annotation [disposalHandler]
  delegated,
}

// endregion disposal

// region multibindings

class IntoSet {
  const IntoSet._();
}

/// The method's return type forms the generic type argument of a Set<T>, and
/// the returned value is contributed to the set. The object graph will pass
/// dependencies to the method as parameters. The Set<T> produced from the
/// accumulation of values will be immutable.
const IntoSet intoSet = IntoSet._();

class IntoMap {
  const IntoMap._();
}

/// The method's return type forms the type argument for the value of a
/// Map<K, V>, and the combination of the annotated key and the returned value
/// is contributed to the map as a key/value pair. The Map<K, V> produced from
/// the accumulation of values will be immutable.
const IntoMap intoMap = IntoMap._();

/// Identifies annotation types that are used to associate keys with values in
/// order to compose a map [IntoMap].
///
/// Every provider method annotated with [IntoMap] must also have an annotation
/// that identifies the key for that map entry. That annotation's type must be
/// annotated with [MapKey].
const MapKey mapKey = MapKey._();

class MapKey {
  const MapKey._();
}

/// A [MapKey] annotation for maps with [String] keys.
@mapKey
class StringKey {
  const factory StringKey(String value) = StringKey._;

  const StringKey._(this.value);

  final String value;
}

/// A [MapKey] annotation for maps with [int] keys.
@mapKey
class IntKey {
  const factory IntKey(int value) = IntKey._;

  const IntKey._(this.value);

  final int value;
}

/// A [MapKey] annotation for maps with [Type] keys.
@mapKey
class TypeKey {
  const factory TypeKey(Type value) = TypeKey._;

  const TypeKey._(this.value);

  final Type value;
}

// endregion multibindings

/// A subcomponent that inherits the bindings from a parent [Component] or
/// [Subcomponent].
/// ```
/// @Subcomponent()
/// abstract class MySubcomponent {}
/// ```
class Subcomponent {
  const factory Subcomponent({
    List<Type> modules,
    Type? builder,
  }) = Subcomponent._;

  const Subcomponent._({
    this.modules = const <Type>[],
    this.builder = null,
  });

  final List<Type> modules;

  /// Builder for this component.
  final Type? builder;
}

class SubcomponentFactory {
  const SubcomponentFactory._();
}

/// Marks a method on a [Component] or [Subcomponent] as a subcomponent factory.
/// ```
/// abstract class MyComponent {
///   @subcomponentFactory
///   MySubcomponent createMySubcomponent();
/// }
/// ```
const SubcomponentFactory subcomponentFactory = SubcomponentFactory._();
