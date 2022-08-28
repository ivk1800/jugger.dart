// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component()
@scope1
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createSubcomponent();
}

@Subcomponent(modules: <Type>[MySubcomponentModule])
@scope2
abstract class MySubcomponent {
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
          const DisposableClassFromSubComponent();
}

class DisposableClassFromSubComponent {
  const DisposableClassFromSubComponent();

  void dispose() {}
}
