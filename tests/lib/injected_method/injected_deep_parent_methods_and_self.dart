// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  MyClass getMyClass();
}

@module
abstract class AppModule {
  @provides
  static int provideInt() => 0;
}

class MyClass extends BaseClass {
  @inject
  const MyClass();

  @inject
  void init(int i) {}
}

class BaseClass extends SuperBaseClass {
  @inject
  const BaseClass();

  @inject
  void initBase(int i) {}
}

class SuperBaseClass {
  @inject
  const SuperBaseClass();

  @inject
  void initSuperBase(int i) {}
}
