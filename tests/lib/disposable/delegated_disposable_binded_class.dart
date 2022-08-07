// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule],
)
@singleton
abstract class AppComponent {
  IMyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClassImpl myClass) async {
    myClass.dispose2();
  }

  @singleton
  @binds
  IMyClass bindMyClass(MyClassImpl impl);
}

abstract class IMyClass {}

@singleton
@Disposable(strategy: DisposalStrategy.delegated)
class MyClassImpl implements IMyClass {
  @inject
  const MyClassImpl();

  void dispose2() {}
}
