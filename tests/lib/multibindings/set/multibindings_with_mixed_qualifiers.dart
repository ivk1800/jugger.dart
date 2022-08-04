// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  @myQualifier
  Set<String> get strings1;

  @Named('test')
  Set<String> get strings2;
}

@module
abstract class Module1 {
  @provides
  @intoSet
  @myQualifier
  static String provideString1() => '1';

  @provides
  @intoSet
  @myQualifier
  static String provideString2() => '2';

  @provides
  @intoSet
  @Named('test')
  static String provideString3() => '3';

  @provides
  @intoSet
  @Named('test')
  static String provideString4() => '4';
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();
