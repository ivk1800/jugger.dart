// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1, Module2],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@Module(includes: <Type>[Module3])
abstract class Module1 {
  @provides
  @singleton
  @Disposable(strategy: DisposalStrategy.delegated)
  static MyClass provideMyClass() => MyClass();
}

@Module(includes: <Type>[Module3])
abstract class Module2 {}

@module
abstract class Module3 {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose2();
  }
}

class MyClass {
  void dispose2() {}
}
