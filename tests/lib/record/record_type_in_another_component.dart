// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule1],
)
abstract class MyComponent1 {
  (String, int) get myRecord;
}

@module
abstract class MyModule1 {
  @provides
  static (String, int) provideMyRecord() => ('', 0);
}

@Component(
  // ignore: deprecated_member_use
  dependencies: <Type>[MyComponent1],
  builder: Component2Builder,
)
abstract class MyComponent2 {
  (String, int) get myRecord;
}

@componentBuilder
abstract class Component2Builder {
  Component2Builder setMyComponent1(MyComponent1 component1);

  MyComponent2 build();
}
