// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent1 {
  Set<String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoSet
  static String provideString1() => '1';

  @provides
  @intoSet
  static String provideString2() => '2';
}

@Component(
  modules: <Type>[Module2],
)
abstract class AppComponent2 {
  Map<int, String> get strings;
}

@module
abstract class Module2 {
  @provides
  @intoMap
  @IntKey(1)
  static String provideString3() => '3';

  @provides
  @intoMap
  @IntKey(2)
  static String provideString4() => '4';
}
