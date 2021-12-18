/// Annotates an abstract class for which a dependency-injected implementation
/// is to be generated from a set of modules.
class Component {
  const factory Component({List<Type> modules, List<Type> dependencies}) =
      Component._;

  const Component._(
      {this.modules = const <Type>[], this.dependencies = const <Type>[]});

  final List<Type> modules;
  final List<Type> dependencies;
}

/// Annotates a class that contributes to the object graph.
class Module {
  const Module._();
}

/// Identifies a type that the injector only instantiates once.
class Singleton {
  const Singleton._();
}

/// Annotates methods of a module to create a provider method binding.
class Provide {
  const Provide._();
}

/// Identifies injectable constructors, methods, and fields.
class Inject {
  const factory Inject() = Inject._;

  const Inject._();
}

/// Annotates abstract methods of a module that delegate bindings.
class Bind {
  const Bind._();
}

const ComponentBuilder componentBuilder = ComponentBuilder._();

/// Annotates a class that contributes to create a component.
class ComponentBuilder {
  const ComponentBuilder._();
}

/// String-based qualifier.
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

const Provide provide = Provide._();

const Module module = Module._();

const Singleton singleton = Singleton._();

const Inject inject = Inject._();

const Bind bind = Bind._();
