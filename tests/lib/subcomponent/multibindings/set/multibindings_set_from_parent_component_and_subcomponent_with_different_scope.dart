// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[MyComponentModule])
@scope1
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent();

  Set<String> get strings;
}

@module
abstract class MyComponentModule {
  @provides
  @intoSet
  @scope1
  static String provideString1() => '1';
}

@Subcomponent(modules: <Type>[MySubcomponentModule])
@scope2
abstract class MySubcomponent {
  Set<String> get strings;
}

@module
abstract class MySubcomponentModule {
  @provides
  @intoSet
  @scope2
  static String provideString2() => '2';
}
