// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[AppModule])
@scope1
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent(MyComponentBuilder builder);
}

@module
abstract class AppModule {
  @scope1
  @provides
  static String provideString() => 'Hello';
}

@Subcomponent(
  modules: <Type>[MyModule],
  builder: MyComponentBuilder,
)
@scope2
abstract class MyComponent {
  int get count;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setDouble(double d);

  MyComponent build();
}

@module
abstract class MyModule {
  @provides
  static int provideCount(String s, double d) => s.length;
}
