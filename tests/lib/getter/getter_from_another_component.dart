// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class AppConfig {
  String get myScreenName => 'my screen';
}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  AppConfig get appConfig;
}

@module
abstract class AppModule {
  @provides
  static AppConfig provideAppConfig() => AppConfig();
}

////////////////////////////////////////////////////////////////////////////////

@Component(
  // ignore: deprecated_member_use
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyScreenModule],
  builder: MyScreenComponentBuilder,
)
@singleton
abstract class MyScreenComponent {
  String get screenName;
}

@module
abstract class MyScreenModule {
  @singleton
  @provides
  static String provideScreenName(AppConfig config) => config.myScreenName;
}

@componentBuilder
abstract class MyScreenComponentBuilder {
  MyScreenComponentBuilder appComponent(AppComponent foldersComponent);

  MyScreenComponent build();
}
