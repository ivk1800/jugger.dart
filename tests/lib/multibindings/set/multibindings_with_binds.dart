// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
@singleton
abstract class AppComponent {
  Set<MyClass> get myClasses;
}

@module
abstract class Module1 {
  @binds
  @intoSet
  MyClass bindMyClassImpl1(MyClassImpl1 impl);

  @binds
  @intoSet
  MyClass bindMyClassImpl2(MyClassImpl2 impl);

  @binds
  @intoSet
  @singleton
  MyClass bindMyClassImpl3(MyClassImpl3 impl);
}

abstract class MyClass {}

class MyClassImpl1 implements MyClass {
  @inject
  const MyClassImpl1();
}

class MyClassImpl2 implements MyClass {
  @inject
  const MyClassImpl2();
}

class MyClassImpl3 implements MyClass {
  @inject
  const MyClassImpl3();
}
