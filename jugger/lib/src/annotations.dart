///
/// TODO(): write documentation
///
class Component {
  const factory Component([List<Type> modules]) = Component._;

  const Component._([this.modules = const <Type>[]]);

  final List<Type> modules;
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