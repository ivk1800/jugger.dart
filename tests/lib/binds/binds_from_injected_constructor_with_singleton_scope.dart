import 'package:jugger/jugger.dart';

abstract class IMainRouter {}

@singleton
class MainRouter implements IMainRouter {
  @inject
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
  @binds
  IMainRouter bindMainRouter(MainRouter impl);
}
