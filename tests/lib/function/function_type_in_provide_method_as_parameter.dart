// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  String get myString;
}

@module
abstract class MyModule {
  @provides
  static void Function() provideMyFunction() => () => null;

  @provides
  static String provideMyString(void Function() param) => '';
}
