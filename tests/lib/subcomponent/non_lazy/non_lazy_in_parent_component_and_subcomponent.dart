// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[MyComponentModule])
@scope1
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent();

  String getString();
}

@module
abstract class MyComponentModule {
  @provides
  @scope1
  @nonLazy
  static String provideString() => '';
}

@Subcomponent(modules: [MySubcomponentModule])
@scope2
abstract class MySubcomponent {
  int getInt();
}

@module
abstract class MySubcomponentModule {
  @provides
  @scope2
  @nonLazy
  static int provideInt() => 0;
}
