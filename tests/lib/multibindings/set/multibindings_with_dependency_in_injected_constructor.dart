// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  MyClass get myClass;
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

class MyClass {
  @inject
  const MyClass(this.strings);

  final Set<String> strings;
}
