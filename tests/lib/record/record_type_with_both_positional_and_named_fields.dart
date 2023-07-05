// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  (List<int>, {int named}) get myRecord;
}

@module
abstract class MyModule {
  @provides
  static (List<int>, {int named}) provideMyRecord() => (<int>[], named: 0);
}
