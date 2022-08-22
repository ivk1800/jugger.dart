// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[Component1Module])
abstract class Component1 {
  Set<FromComponent> get classes;

  @subcomponentFactory
  Component2 createComponent2();
}

@module
abstract class Component1Module {
  @provides
  @intoSet
  static FromComponent provideClass() => const FromComponent1();
}

@Subcomponent(
  modules: <Type>[Component2Module],
)
@scope1
abstract class Component2 {
  Set<FromComponent> get classes;

  @subcomponentFactory
  Component3 createComponent3();
}

@module
abstract class Component2Module {
  @provides
  @intoSet
  static FromComponent provideClass() => const FromComponent2();
}

@Subcomponent(
  modules: <Type>[Component3Module],
)
@scope2
abstract class Component3 {
  Set<FromComponent> get classes;
}

@module
abstract class Component3Module {
  @provides
  @intoSet
  static FromComponent provideClass() => const FromComponent3();
}

abstract class FromComponent {}

class FromComponent1 implements FromComponent {
  const FromComponent1();
}

class FromComponent2 implements FromComponent {
  const FromComponent2();
}

class FromComponent3 implements FromComponent {
  const FromComponent3();
}
