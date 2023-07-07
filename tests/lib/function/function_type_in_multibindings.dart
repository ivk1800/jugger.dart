// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  Map<String, void Function()> get myFunctions;
}

@module
abstract class MyModule {
  @provides
  @intoMap
  @StringKey('1')
  static void Function() provideMyFunction1() => () => null;

  @provides
  @intoMap
  @StringKey('2')
  static void Function() provideMyFunction2() => () => null;
}
