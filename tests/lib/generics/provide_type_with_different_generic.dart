// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  Future<String> get stringFuture;

  Future<int> get intFuture;
}

@module
abstract class AppModule {
  @provides
  static Future<String> provideStringFuture() => Future<String>.value('');

  @provides
  static Future<int> provideIntFuture() => Future<int>.value(1);
}
