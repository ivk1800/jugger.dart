// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<int, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @singleton
  static int provideInt() => 0;

  @provides
  @intoMap
  @IntKey(1)
  static String provideString1(int i) => i.toString();

  @provides
  @intoMap
  @IntKey(2)
  static String provideString2(int i) => i.toString();
}