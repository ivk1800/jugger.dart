// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  Pattern get myTypedef;
}

@module
abstract class MyModule {
  @provides
  static String provideMyString() => '';

  @binds
  Pattern provideMyTypedef(MyTypedef s);
}

typedef MyTypedef = String;
