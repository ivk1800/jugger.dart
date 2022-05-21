// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class AppConfig {}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  @Named('prod')
  AppConfig get prodAppConfig;

  @Named('prod')
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
  @Named('prod')
  static AppConfig provideProdAppConfig() => AppConfig();

  @singleton
  @provides
  @Named('dev')
  static AppConfig provideDevAppConfig() => AppConfig();
}
