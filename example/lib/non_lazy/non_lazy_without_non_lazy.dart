// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class LazyRepository {}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  LazyRepository getLazyRepository();
}

@module
abstract class AppModule {
  @singleton
  @provides
  static LazyRepository provideLazyRepository() => LazyRepository();
}
