import 'package:flutter_example/src/app/config.dart';
import 'package:jugger/jugger.dart' as j;

@j.module
abstract class AppModule {
  @j.provides
  @j.singleton
  static Config provideConfig() => const Config(
        packagesRepositoryType: PackagesRepositoryType.$default,
      );
}
