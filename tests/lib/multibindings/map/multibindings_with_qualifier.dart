// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  @myQualifier
  Map<int, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  @myQualifier
  static String provideString1() => '1';

  @provides
  @intoMap
  @IntKey(2)
  @myQualifier
  static String provideString2() => '2';
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();
