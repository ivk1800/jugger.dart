// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  List<String> get myTypedef;
}

@module
abstract class MyModule {
  @provides
  static MyTypedef provideMyTypedef() => [];
}

typedef MyTypedef = List<String>;
