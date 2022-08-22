// ignore_for_file: avoid_classes_with_only_static_members
import 'package:jugger/jugger.dart';

class AppConfig {
  const AppConfig(this.baseUrl);

  final String baseUrl;
}

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  AppConfig getConfig();
}

@module
abstract class AppModule {
  @provides
  @Named('dev')
  static AppConfig provideDevAppConfig() {
    return const AppConfig('https://dev.com/');
  }

  @provides
  @Named('release')
  static AppConfig provideReleaseAppConfig() {
    return const AppConfig('https://release.com/');
  }

  @provides
  @singleton
  static AppConfig provideAppConfig(
    @Named('dev') AppConfig dev,
    @Named('release') AppConfig release,
  ) =>
      dev;
}
