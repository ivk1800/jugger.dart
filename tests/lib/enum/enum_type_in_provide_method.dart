// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  MyClass get myClass;
}

@module
abstract class MyModule {
  @provides
  static MyEnum provideMyEnum() => MyEnum.first;

  @provides
  static MyClass provideMyClass(MyEnum myEnum) => MyClass(myEnum);
}

class MyClass {
  final MyEnum myEnum;

  MyClass(this.myEnum);
}

enum MyEnum {
  first,
}
