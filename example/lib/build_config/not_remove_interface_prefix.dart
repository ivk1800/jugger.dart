// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class IAppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello() => 'hello';
}
