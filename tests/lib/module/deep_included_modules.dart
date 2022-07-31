// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  String get string;
}

@Module(includes: <Type>[Module2])
abstract class Module1 {
  @provides
  static String providerString(int i, double d, bool b) => '$i$d';
}

@Module(includes: <Type>[Module3])
abstract class Module2 {
  @provides
  static int providerInt() => 0;
}

@Module(includes: <Type>[Module4])
abstract class Module3 {
  @provides
  static double providerDouble() => 0.0;
}

@module
abstract class Module4 {
  @provides
  static bool providerBool() => false;
}
