// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

abstract class IMainRouter implements IMyScreenRouter {}

abstract class IMyScreenRouter {}

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
  static IMainRouter provideMainRouter() => MainRouter();
}

////////////////////////////////////////////////////////////////////////////////

@Component(
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyScreenModule],
)
abstract class MyScreenComponent {
  IMyScreenRouter get myScreenRouter;
}

@module
abstract class MyScreenModule {
  @singleton
  @binds
  IMyScreenRouter bindFoldersScreenRouter(IMainRouter router);
}

@componentBuilder
abstract class MyScreenComponentBuilder {
  MyScreenComponentBuilder appComponent(AppComponent foldersComponent);

  MyScreenComponent build();
}
