// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  (String, int) get myRecord;
}

@module
abstract class MyModule {
  @provides
  static (int, int) provideMyRecord2() => (0, 0);

  @provides
  static (String, int) provideMyRecord((int, int) param) => ('', 0);
}
