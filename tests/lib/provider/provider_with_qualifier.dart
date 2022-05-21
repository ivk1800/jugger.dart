// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  @myQualifier
  Config getConfig1();

  Config getConfig2();
}

@module
abstract class AppModule {
  @provides
  @myQualifier
  static Config provideConfig1(
    IProvider<Config> configProvider,
  ) =>
      configProvider.get();

  @provides
  static Config provideConfig2(
    @myQualifier IProvider<Config> configProvider,
  ) =>
      configProvider.get();
}

class Config {
  @inject
  const Config();
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();
