// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[AppModule])
@scope1
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createSubcomponent();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @provides
  @disposable
  @scope1
  static DisposableClassFromParent provideDisposableClassFromParent() =>
      const DisposableClassFromParent();
}

@Subcomponent()
@scope2
abstract class MySubcomponent {
  DisposableClassFromParent get disposableClassFromParent;
}

class DisposableClassFromParent {
  const DisposableClassFromParent();

  void dispose() {}
}
