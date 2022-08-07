// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent1 {
  Map<int, String> get strings;
  Map<String, int> get ints;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  static String provideString1() => '1';

  @provides
  @intoMap
  @IntKey(2)
  static String provideString2() => '2';

  @provides
  @intoMap
  @StringKey("1")
  static int provideInt1() => 1;

  @provides
  @intoMap
  @StringKey("2")
  static int provideInt2() => 2;
}
