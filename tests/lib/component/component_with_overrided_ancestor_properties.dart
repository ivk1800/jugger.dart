// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class Ancestor1 {
  String get string;
}

abstract class Ancestor2 extends Ancestor1 {
  @override
  String get string;
}

@Component(modules: <Type>[Module1])
abstract class AppComponent extends Ancestor2 {
  @override
  String get string;
}

@module
abstract class Module1 {
  @provides
  static String provideString() => 's';
}
