// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  builder: AppComponentBuilder,
)
abstract class AppComponent {
  MyClass1 getMyClass1();

  Future<void> dispose();
}

@componentBuilder
abstract class AppComponentBuilder {
  @disposable
  AppComponentBuilder setMyClass1(MyClass1 c);

  AppComponent build();
}

class BaseClass {
  const BaseClass();

  void dispose() {}
}

class MyClass1 extends BaseClass {
  const MyClass1();
}
