// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  MyClass getMyClass();
}

@module
abstract class AppModule {
  @provides
  static String provideString() => '';

  @provides
  static int provideInt() => 0;
}

class MyClass {
  @inject
  const MyClass(this.i, this.s);

  final int i;
  final String s;

  @inject
  void init(int i) {}
}
