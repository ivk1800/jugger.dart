// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getName();

  int getVersion();
}

@module
abstract class AppModule {
  @provides
  static int provideVersion() => 1;

  @provides
  static String provideName(Config myClass) =>
      'version:${myClass.version.get()}';
}

class Config {
  @inject
  const Config(this.version);

  final ILazy<int> version;
}
