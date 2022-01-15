// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  @Named('name')
  String get name;

  @Named('name')
  int get version;
}

@module
abstract class AppModule {
  @provides
  @Named('name')
  static String provideName() => '';

  @provides
  @Named('name')
  static int provideVersion() => 0;
}
