// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class AppConfig {}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  @dev
  AppConfig get devAppConfig;

  @dev
  AppConfig getDevAppConfig();

  @prod
  AppConfig get prodAppConfig;

  @prod
  AppConfig getProdAppConfig();
}

@module
abstract class AppModule {
  @singleton
  @provides
  @prod
  static AppConfig provideProdAppConfig() => AppConfig();

  @singleton
  @provides
  @dev
  static AppConfig provideDevAppConfig() => AppConfig();
}

@qualifier
class Prod {
  const Prod();
}

const Prod prod = Prod();

@qualifier
class Dev {
  const Dev();
}

const Dev dev = Dev();
