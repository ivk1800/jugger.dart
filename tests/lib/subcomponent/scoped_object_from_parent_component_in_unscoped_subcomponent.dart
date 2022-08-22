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
  static String provideString() => '';
}

@Subcomponent()
abstract class MySubcomponent {
  String getString();
}
