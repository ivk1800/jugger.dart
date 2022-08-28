// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Set<String> get strings;
}

@Module(includes: <Type>[Module2])
abstract class Module1 {
  @provides
  @intoSet
  static String provideString() => '1';
}

@Module(includes: <Type>[Module3])
abstract class Module2 {
  @provides
  @intoSet
  static String provideString() => '2';
}

@module
abstract class Module3 {
  @provides
  @intoSet
  static String provideString() => '3';
}
