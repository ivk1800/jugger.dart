// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[MyComponentModule])
@singleton
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent();

  String getString();
}

@module
abstract class MyComponentModule {
  @provides
  @singleton
  @nonLazy
  static String provideString() => '';
}

@Subcomponent()
abstract class MySubcomponent {
  String getString();
}
