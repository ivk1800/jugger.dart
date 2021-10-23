// non_lazy/simple
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class NonLazyRepository {}

class LazyRepository {}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  NonLazyRepository getNonLazyRepository();

  LazyRepository getLazyRepository();
}

@module
abstract class AppModule {
  @singleton
  @provide
  @nonLazy
  static NonLazyRepository provideNonLazyRepository() => NonLazyRepository();

  @singleton
  @provide
  static LazyRepository provideLazyRepository() => LazyRepository();
}
