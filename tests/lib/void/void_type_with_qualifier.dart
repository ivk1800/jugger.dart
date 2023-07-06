// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  @myQualifier
  void get myVoid;
}

@module
abstract class MyModule {
  @provides
  @myQualifier
  static void provideMyVoid() => null;
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();
