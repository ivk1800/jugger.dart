import 'package:flutter_example/src/app/config.dart';
import 'package:flutter_example/src/app/data/data.dart';
import 'package:flutter_example/src/data_impl/broken_packages_repository.dart';
import 'package:flutter_example/src/data_impl/data_impl.dart';
import 'package:jugger/jugger.dart' as j;

@j.module
abstract class DataModule {
  @j.provides
  static IPackagesRepository providePackagesRepository(
    j.ILazy<PackagesRepositoryImpl> defaultRepository,
    j.ILazy<BrokenPackagesRepository> brokenRepository,
    Config config,
  ) {
    switch (config.packagesRepositoryType) {
      case PackagesRepositoryType.$default:
        return defaultRepository.value;
      case PackagesRepositoryType.broken:
        return brokenRepository.value;
    }
  }
}
