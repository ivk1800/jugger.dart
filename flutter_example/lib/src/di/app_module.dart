import 'package:flutter_example/src/app/config.dart';
import 'package:jugger/jugger.dart' as j;

import 'scope.dart';

@j.module
abstract class AppModule {
  @j.provides
  @applicationScope
  static Config provideConfig() => const Config(
        packagesRepositoryType: PackagesRepositoryType.$default,
      );
}
