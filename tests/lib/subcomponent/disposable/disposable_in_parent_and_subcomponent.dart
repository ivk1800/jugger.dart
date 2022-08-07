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
      DisposableClassFromParent();
}

@Subcomponent(
  modules: <Type>[MySubcomponentModule],
)
@scope2
abstract class MySubcomponent {
  DisposableClassFromParent get disposableClassFromParent;

  DisposableClassFromSubComponent get disposableClassFromSubComponent;

  Future<void> dispose();
}

@module
abstract class MySubcomponentModule {
  @provides
  @disposable
  @scope2
  static DisposableClassFromSubComponent
      provideDisposableClassFromSubComponent() =>
          DisposableClassFromSubComponent();
}

class DisposableClassFromParent {
  const DisposableClassFromParent();

  void dispose() {}
}

class DisposableClassFromSubComponent {
  const DisposableClassFromSubComponent();

  void dispose() {}
}
