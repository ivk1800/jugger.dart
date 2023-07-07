// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule1],
)
abstract class MyComponent1 {
  void Function() get myFunction;
}

@module
abstract class MyModule1 {
  @provides
  static void Function() provideMyFunction() => () => null;
}

@Component(
  // ignore: deprecated_member_use
  dependencies: <Type>[MyComponent1],
  builder: Component2Builder,
)
abstract class MyComponent2 {
  void Function() get myFunction;
}

@componentBuilder
abstract class Component2Builder {
  Component2Builder setMyComponent1(MyComponent1 component1);

  MyComponent2 build();
}
