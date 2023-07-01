// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  Map<String, (String, int)> get myRecords1;

  Map<String, (bool, int)> get myRecords2;

  Map<String, (bool, List<String>)> get myRecords3;
}

@module
abstract class MyModule {
  @provides
  @intoMap
  @StringKey('1')
  static (String, int) provide1() => ('', 0);

  @provides
  @intoMap
  @StringKey('2')
  static (String, int) provide2() => ('', 0);

  @provides
  @intoMap
  @StringKey('2')
  static (bool, int) provide3() => (false, 0);

  @provides
  @intoMap
  @StringKey('1')
  static (bool, List<String>) provide4() => (false, <String>['4']);

  @provides
  @intoMap
  @StringKey('2')
  static (bool, List<String>) provide5() => (false, <String>['5']);
}
