// non_lazy/simple
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class MainRouter {}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  MainRouter getMainRouter();
}

@module
abstract class AppModule {
  @singleton
  @provide
  static MainRouter provideMainRouter() => MainRouter();
}
