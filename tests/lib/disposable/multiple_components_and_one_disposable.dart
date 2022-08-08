// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppComponentModule],
)
abstract class AppComponent {
  DisposableClass getDisposableClass();

  Future<void> dispose();
}

@Component()
abstract class AppComponent2 {}

@module
abstract class AppComponentModule {}

@singleton
@disposable
class DisposableClass {
  @inject
  const DisposableClass();

  void dispose() {}
}
