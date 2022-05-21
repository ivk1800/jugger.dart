// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class Ancestor1 {
  void inject1(InjectedClass c);
}

abstract class Ancestor2 extends Ancestor1 {
  void inject2(InjectedClass c);
}

@Component(modules: <Type>[Module1])
abstract class AppComponent extends Ancestor2 {
  void inject3(InjectedClass c);
}

@module
abstract class Module1 {
  @provides
  static String provideString() => 's';
}

class InjectedClass {
  @inject
  late String s;
}
