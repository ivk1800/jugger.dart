// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
@singleton
abstract class Component1 {
  MyMixin getMyMixin();
}

@module
abstract class AppModule {
  @singleton
  @provides
  static MyMixinImpl provideMyMixinImpl() => MyMixinImpl();

  @singleton
  @binds
  MyMixin bindMyMixin(MyMixinImpl impl);
}

mixin MyMixin {}

class MyMixinImpl with MyMixin {}
