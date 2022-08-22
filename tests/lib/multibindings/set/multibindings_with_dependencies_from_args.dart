// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
  builder: AppComponentBuilder,
)
abstract class AppComponent {
  Set<String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoSet
  static String provideString1(int i) => i.toString();
}

@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setInt(int i);

  AppComponent build();
}
