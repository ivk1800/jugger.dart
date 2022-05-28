// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class Class1 {
  String getString1();
}

abstract class Class2 {
  String get string2;
}

abstract class Class3 {
  String get string3;
}

@Component(modules: <Type>[Module1])
abstract class AppComponent extends Class3 implements Class1, Class2 {
  String getString0();
}

@module
abstract class Module1 {
  @provides
  static String provideString() => 's';
}
