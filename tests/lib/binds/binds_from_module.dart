// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class IMainRouter {}

class MainRouter implements IMainRouter {
  const MainRouter();
}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  IMainRouter getMainRouter();
}

@module
abstract class AppModule {
  @singleton
  @provides
  static MainRouter provideMainRouter() => const MainRouter();

  @singleton
  @binds
  IMainRouter bindMainRouter(MainRouter impl);
}
