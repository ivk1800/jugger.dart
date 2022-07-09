// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class Disposer {
  Future<void> dispose();
}

@Component(
  modules: <Type>[AppModule],
)
abstract class AppComponent extends Disposer {
  MyClass getMyClass();
}

@module
abstract class AppModule {
  @provides
  @singleton
  @disposable
  static MyClass provideMyClass() => MyClass();
}

class MyClass {
  const MyClass();

  void dispose() {}
}
