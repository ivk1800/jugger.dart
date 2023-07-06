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
  static void provideMyVoid() => null;
}

class MyClass {
  final void myVoid;

  @inject
  MyClass(this.myVoid);
}
