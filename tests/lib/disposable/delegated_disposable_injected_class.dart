// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppComponentModule],
)
@singleton
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppComponentModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose();
  }
}

@singleton
@Disposable(strategy: DisposalStrategy.delegated)
class MyClass {
  @inject
  const MyClass();

  void dispose() {}
}
