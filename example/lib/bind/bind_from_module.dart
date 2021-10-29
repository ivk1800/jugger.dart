// non_lazy/simple
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class IMainRouter {}

class MainRouter implements IMainRouter {}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  IMainRouter getFoldersRouter();
}

@module
abstract class AppModule {
  @singleton
  @provide
  static MainRouter provideMainRouter() => MainRouter();

  @singleton
  @bind
  IMainRouter bindMainRouter(MainRouter impl);
}
