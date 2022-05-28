// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class Class1 {
  String getString();
}

abstract class Class2 {
  String get string;
}

@Component(modules: <Type>[Module1])
abstract class AppComponent implements Class1, Class2 {}

@module
abstract class Module1 {
  @provides
  static String provideString() => 's';
}
