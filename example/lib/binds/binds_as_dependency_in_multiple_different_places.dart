// non_lazy/simple
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class IMainRouter {}

class MainRouter implements IMainRouter {
  @inject
  const MainRouter();
}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  IMainRouter getMainRouter();

  String getString();
}

@module
abstract class AppModule {
  @provides
  static String provideString(MainRouter mainRouter) =>
      mainRouter.runtimeType.toString();

  @binds
  IMainRouter bindMainRouter(MainRouter impl);
}
