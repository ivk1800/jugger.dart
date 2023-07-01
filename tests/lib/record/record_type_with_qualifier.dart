// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  @myQualifier
  (String, int) get myRecord;
}

@module
abstract class MyModule {
  @provides
  @myQualifier
  static (String, int) provideMyRecord() => ('', 0);
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();
