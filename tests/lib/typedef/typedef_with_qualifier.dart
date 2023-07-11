// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  @myQualifier
  MyTypedef get myVoid;
}

@module
abstract class MyModule {
  @provides
  @myQualifier
  static MyTypedef provideMyVoid() => '';
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();

typedef MyTypedef = String;
