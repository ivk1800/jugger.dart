// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[Component1Module])
abstract class Component1 {
  @subcomponentFactory
  Component2 createComponent2();
}

@module
abstract class Component1Module {
  @provides
  static FromComponent1 provideClass() => const FromComponent1();
}

@Subcomponent(
  modules: <Type>[Component2Module],
)
@scope1
abstract class Component2 {
  @subcomponentFactory
  Component3 createComponent3();
}

@module
abstract class Component2Module {
  @provides
  static FromComponent2 provideClass() => const FromComponent2();
}

@Subcomponent(
  modules: <Type>[Component3Module],
)
@scope2
abstract class Component3 {
  FromComponent3 getFromComponent3();
}

@module
abstract class Component3Module {
  @provides
  static FromComponent3 provideClass(
    FromComponent1 fromComponent1,
    FromComponent2 fromComponent2,
  ) =>
      const FromComponent3();
}

class FromComponent1 {
  const FromComponent1();
}

class FromComponent2 {
  const FromComponent2();
}

class FromComponent3 {
  const FromComponent3();
}
