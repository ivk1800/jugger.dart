// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
@singleton
abstract class AppComponent {
  Map<int, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  @singleton
  static String provideString1() => '1';

  @provides
  @intoMap
  @IntKey(2)
  static String provideString2() => '2';
}
