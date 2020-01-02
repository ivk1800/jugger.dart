// ignore_for_file: flutter_style_todos

///
/// TODO(): write documentation
///
class Component {
  const factory Component({List<Type> modules, List<Type> dependencies}) =
      Component._;

  const Component._(
      {this.modules = const <Type>[], this.dependencies = const <Type>[]});

  final List<Type> modules;
  final List<Type> dependencies;
}

const Module module = Module._();

///
/// TODO(): write documentation
///
class Module {
  const Module._();
}

const Singleton singleton = Singleton._();

///
/// TODO(): write documentation
///
class Singleton {
  const Singleton._();
}

const Provide provide = Provide._();

///
/// TODO(): write documentation
///
class Provide {
  const Provide._();
}

///
/// TODO(): write documentation
///
class Inject {
  const factory Inject() = Inject._;

  const Inject._();
}

///
/// TODO(): write documentation
///
const Inject inject = Inject();

const Bind bind = Bind._();

///
/// TODO(): write documentation
///
class Bind {
  const Bind._();
}

const ComponentBuilder componentBuilder = ComponentBuilder._();

///
/// TODO(): write documentation
///
class ComponentBuilder {
  const ComponentBuilder._();
}

///
/// TODO(): write documentation
///
class Named {
  const factory Named(String name) = Named._;

  const Named._(this.name);

  final String name;
}
