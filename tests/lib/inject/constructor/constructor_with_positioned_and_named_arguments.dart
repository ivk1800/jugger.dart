// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[MyModule])
abstract class MyComponent {
  MyClass get myClass;
}

@module
abstract class MyModule {
  @provides
  static String providerString() => '';

  @provides
  static int providerInt() => 0;
}

class MyClass {
  @inject
  const MyClass(this.s1, this.i2, {required this.i1, required this.s2});

  final String s1;
  final String s2;
  final int i1;
  final int i2;
}
