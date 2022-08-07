// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent1 {
  Set<String> get strings;
  Set<int> get ints;
}

@module
abstract class Module1 {
  @provides
  @intoSet
  static String provideString1() => '1';

  @provides
  @intoSet
  static String provideString2() => '2';

  @provides
  @intoSet
  static int provideInt1() => 1;

  @provides
  @intoSet
  static int provideInt2() => 2;
}
