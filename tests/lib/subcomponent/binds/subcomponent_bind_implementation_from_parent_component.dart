// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

abstract class IMyInterface {}

class MyImplementation implements IMyInterface {}

@Component(modules: <Type>[MyComponentModule])
@scope1
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMyComponent();
}

@module
abstract class MyComponentModule {
  @provides
  static MyImplementation provideMyImplementation() => MyImplementation();
}

@Subcomponent(
  modules: <Type>[MySubcomponentModule],
)
@scope2
abstract class MySubcomponent {
  IMyInterface get myInterface;
}

@module
abstract class MySubcomponentModule {
  @binds
  IMyInterface bindMyInterface(MyImplementation impl);
}
