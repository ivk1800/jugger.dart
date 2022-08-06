// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Set<String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoSet
  @singleton
  static String provideString1() => '1';

  @provides
  @intoSet
  static String provideString2() => '2';
}
