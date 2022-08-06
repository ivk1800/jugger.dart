// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<int, String> get strings;
}

@Module(includes: [Module2])
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  static String provideString() => '1';
}

@Module(includes: [Module3])
abstract class Module2 {
  @provides
  @intoMap
  @IntKey(2)
  static String provideString() => '2';
}

@module
abstract class Module3 {
  @provides
  @intoMap
  @IntKey(3)
  static String provideString() => '3';
}
