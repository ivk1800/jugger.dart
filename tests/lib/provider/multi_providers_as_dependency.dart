// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getName();
}

@module
abstract class AppModule {
  @provides
  static String provideName(
    IProvider<Config> configProvider,
    IProvider<Config2> config2Provider,
  ) =>
      'hello';
}

class Config {
  @inject
  const Config();
}

class Config2 {
  @inject
  const Config2();
}
