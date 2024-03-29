// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class AppConfig {}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  @myQualifier
  AppConfig get appConfig;

  @myQualifier
  AppConfig getAppConfig();

  @MyQualifier()
  AppConfig get appConfig2;

  @MyQualifier()
  AppConfig getAppConfig2();
}

@module
abstract class AppModule {
  @singleton
  @provides
  @myQualifier
  static AppConfig provideAppConfig() => AppConfig();
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();
