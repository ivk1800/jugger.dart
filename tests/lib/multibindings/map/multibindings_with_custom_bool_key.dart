// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<bool, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @MyKey(false)
  static String provideString1() => '1';

  @provides
  @intoMap
  @MyKey(true)
  static String provideString2() => '2';
}

@mapKey
class MyKey {
  const MyKey(this.value);

  final bool value;
}
