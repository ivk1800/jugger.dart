// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class AppConfig {}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  AppConfig get prodAppConfig;

  AppConfig getProdAppConfig();

  @Named('dev')
  AppConfig get devAppConfig;

  @Named('dev')
  AppConfig getDevAppConfig();
}

@module
abstract class AppModule {
  @singleton
  @provides
  @Named('dev')
  static AppConfig provideDevAppConfig() => AppConfig();

  @singleton
  @provides
  static AppConfig provideAppConfig() => AppConfig();
}
