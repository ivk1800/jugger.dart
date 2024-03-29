// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class MainRouter {}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  MainRouter getMainRouter();
}

@module
abstract class AppModule {
  @singleton
  @provides
  static MainRouter provideMainRouter() => MainRouter();
}
