// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  int get i;
}

@module
abstract class Module1 {
  @provides
  @singleton
  static int provideInt(Set<String> strings) => strings.length;

  @provides
  @intoSet
  static String provideString1() => '1';

  @provides
  @intoSet
  static String provideString2() => '2';
}
