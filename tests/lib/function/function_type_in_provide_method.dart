// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  void Function() get myFunction;
}

@module
abstract class MyModule {
  @provides
  static void Function() provideMyFunction() => () => null;
}
