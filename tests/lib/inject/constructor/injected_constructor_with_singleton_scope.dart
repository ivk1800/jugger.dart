// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(MyClass myClass) => myClass.toString();
}

@singleton
class MyClass {
  @inject
  const MyClass();
}
