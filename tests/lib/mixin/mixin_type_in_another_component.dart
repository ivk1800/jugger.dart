// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule1],
)
abstract class MyComponent1 {
  MyMixin get myMixin;
}

@module
abstract class MyModule1 {
  @provides
  static MyMixin provideMyMixin() => MyMixinImpl();
}

@Component(
  dependencies: <Type>[MyComponent1],
  builder: Component2Builder,
)
abstract class MyComponent2 {
  MyMixin get myMixin;
}

@componentBuilder
abstract class Component2Builder {
  Component2Builder setMyComponent1(MyComponent1 component1);

  MyComponent2 build();
}

mixin MyMixin {}

class MyMixinImpl with MyMixin {}
