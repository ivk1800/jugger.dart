// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<String, int> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @StringKey('1')
  static int provideInt1() => 1;

  @provides
  @intoMap
  @StringKey('2')
  static int provideInt2() => 2;
}
