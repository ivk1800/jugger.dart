// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[AppModule])
@scope1
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent();
}

@module
abstract class AppModule {
  @scope1
  @provides
  static String provideString() => 'Hello';
}

@Subcomponent(modules: <Type>[MyModule])
@scope2
abstract class MyComponent {
  int get count;
}

@module
abstract class MyModule {
  @provides
  static int provideCount(String s) => s.length;
}
