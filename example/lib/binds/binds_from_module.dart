// non_lazy/simple
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class IMainRouter {}

class MainRouter implements IMainRouter {}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  IMainRouter getMainRouter();
}

@module
abstract class AppModule {
  @singleton
  @provides
  static MainRouter provideMainRouter() => MainRouter();

  @singleton
  @binds
  IMainRouter bindMainRouter(MainRouter impl);
}
