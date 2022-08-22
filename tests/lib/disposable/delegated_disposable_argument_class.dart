// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module],
  builder: AppComponentBuilder,
)
abstract class AppComponent {
  MyClass1 getMyClass1();

  MyClass2 get myClass2;

  Future<void> dispose();
}

@module
abstract class Module {
  @disposalHandler
  static Future<void> disposeMyClass2(MyClass2 myClass2) async =>
      myClass2.dispose2();

  @disposalHandler
  static Future<void> disposeMyClass1(MyClass1 myClass1) async =>
      myClass1.dispose2();
}

@componentBuilder
abstract class AppComponentBuilder {
  @Disposable(strategy: DisposalStrategy.delegated)
  AppComponentBuilder setMyClass1(MyClass1 c);

  @Disposable(strategy: DisposalStrategy.delegated)
  AppComponentBuilder setMyClass2(MyClass2 c);

  AppComponent build();
}

class MyClass1 {
  const MyClass1();

  void dispose2() {}
}

class MyClass2 {
  const MyClass2();

  void dispose2() {}
}
