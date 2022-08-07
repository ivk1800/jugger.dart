// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[MyComponentModule])
@singleton
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent();

  Set<String> get strings;
}

@module
abstract class MyComponentModule {
  @provides
  @intoSet
  static String provideString1() => '1';

  @provides
  @intoSet
  static String provideString2() => '2';
}

@Subcomponent()
abstract class MySubcomponent {
  Set<String> get strings;
}
