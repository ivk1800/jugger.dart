// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.appVersion);

  final String appVersion;
}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get appVersion;
}

@module
abstract class AppModule {
  @singleton
  @provide
  @Named('dev')
  static AppConfig provideDevAppConfig() => AppConfig('1.0');

  @singleton
  @provide
  static String provideAppVersion(
    @Named('dev') AppConfig appConfig,
  ) =>
      appConfig.appVersion;
}
