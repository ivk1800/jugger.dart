// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(
  builder: Component1Builder,
)
abstract class Component1 {
  @subcomponentFactory
  Component2 createComponent2(Component2Builder builder);
}

@componentBuilder
abstract class Component1Builder {
  Component1Builder setFromComponent1(FromComponent1 fromComponent1);

  Component1 build();
}

@Subcomponent(
  builder: Component2Builder,
)
@scope1
abstract class Component2 {
  @subcomponentFactory
  Component3 createComponent3();
}

@componentBuilder
abstract class Component2Builder {
  Component2Builder setFromComponent2(FromComponent2 fromComponent1);

  Component2 build();
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
