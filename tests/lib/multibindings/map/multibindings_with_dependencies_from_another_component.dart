// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class Component1 {
  int get i;
}

@module
abstract class Module1 {
  @provides
  static int provideInt() => 0;
}

@Component(modules: <Type>[Module2], dependencies: <Type>[Component1])
abstract class Component2 {
  Map<int, String> get strings;
}

@module
abstract class Module2 {
  @provides
  @intoMap
  @IntKey(1)
  static String provideString1(int i) => i.toString();
}

@componentBuilder
abstract class Component2Builder {
  Component2Builder setComponent1(Component1 component1);

  Component2 build();
}
