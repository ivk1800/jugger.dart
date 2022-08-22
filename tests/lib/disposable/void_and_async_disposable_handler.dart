// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppComponentModule],
)
@singleton
abstract class AppComponent {
  VoidClass getMyClass();

  AsyncClass getAsyncClass();

  Future<void> dispose();
}

@module
abstract class AppComponentModule {
  @disposalHandler
  static void disposeVoidClass(VoidClass myClass) async {
    myClass.dispose();
  }

  @disposalHandler
  static Future<void> disposeAsyncClass(AsyncClass myClass) =>
      myClass.dispose();
}

@singleton
@Disposable(strategy: DisposalStrategy.delegated)
class VoidClass {
  @inject
  const VoidClass();

  void dispose() {}
}

@singleton
@Disposable(strategy: DisposalStrategy.delegated)
class AsyncClass {
  @inject
  const AsyncClass();

  Future<void> dispose() async {}
}
