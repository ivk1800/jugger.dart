// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<MyEnum, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @MyKey(MyEnum.b)
  static String provideString1() => '1';

  @provides
  @intoMap
  @MyKey(MyEnum.a)
  static String provideString2() => '2';
}

@mapKey
class MyKey {
  const MyKey(this.value);

  final MyEnum value;
}

enum MyEnum { a, b }
