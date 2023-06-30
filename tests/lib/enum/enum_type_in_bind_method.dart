// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  MyInterface get myInterface;
}

@module
abstract class MyModule {
  @provides
  static MyEnum provideMyEnum() => MyEnum.first;

  @binds
  MyInterface bindMyInterface(MyEnum impl);
}

enum MyEnum implements MyInterface {
  first,
}

abstract class MyInterface {}
