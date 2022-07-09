// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose2();
  }

  @provides
  @singleton
  @Disposable(strategy: DisposalStrategy.delegated)
  static MyClass provideMyClass() => MyClass();
}

class MyClass {
  void dispose2() {}
}
