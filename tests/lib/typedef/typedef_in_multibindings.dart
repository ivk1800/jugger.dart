// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  Map<String, MyTypedef> get myRecords1;
}

@module
abstract class MyModule {
  @provides
  @intoMap
  @StringKey('1')
  static MyTypedef provide1() => '1';

  @provides
  @intoMap
  @StringKey('2')
  static MyTypedef provide2() => '2';
}

typedef MyTypedef = String;
