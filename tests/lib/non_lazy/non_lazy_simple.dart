// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class NonLazyRepository {}

class LazyRepository {}

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  NonLazyRepository getNonLazyRepository();

  LazyRepository getLazyRepository();
}

@module
abstract class AppModule {
  @singleton
  @provides
  @nonLazy
  static NonLazyRepository provideNonLazyRepository() => NonLazyRepository();

  @singleton
  @provides
  static LazyRepository provideLazyRepository() => LazyRepository();
}
