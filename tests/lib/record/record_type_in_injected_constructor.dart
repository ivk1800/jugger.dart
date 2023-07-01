// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  MyClass get myClass;
}

@module
abstract class MyModule {
  @provides
  static (String, int) provideMyRecord() => ('', 0);
}

class MyClass {
  final (String, int) myRecord;

  @inject
  MyClass(this.myRecord);
}
