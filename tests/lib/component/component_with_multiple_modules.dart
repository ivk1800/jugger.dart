// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module1, Module2])
abstract class AppComponent {
  String getString();

  int getInt();
}

@module
abstract class Module1 {
  @provides
  static String provideString() => 's';
}

@module
abstract class Module2 {
  @provides
  static int provideInt() => 0;
}
