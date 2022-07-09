// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass1 getMyClass1();

  MyClass2 get myClass2;

  Future<void> dispose();
}

@componentBuilder
abstract class AppComponentBuilder {
  @disposable
  AppComponentBuilder setMyClass1(MyClass1 c);

  @disposable
  AppComponentBuilder setMyClass2(MyClass2 c);

  AppComponent build();
}

class MyClass1 {
  const MyClass1();

  void dispose() {}
}

class MyClass2 {
  const MyClass2();

  void dispose() {}
}
