// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
@myScope
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule {
  @provides
  static String provideString() => 'Hello';
}

@scope
class MyScope {
  const MyScope._();
}

const MyScope myScope = MyScope._();
