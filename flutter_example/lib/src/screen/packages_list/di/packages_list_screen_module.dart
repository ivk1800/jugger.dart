import 'package:flutter_example/src/screen/packages_list/package_model_mapper.dart';
import 'package:jugger/jugger.dart' as j;

@j.module
abstract class PackagesListScreenModule {
  // provide method example
  @j.provides
  static PackageModelMapper providePackageModelMapper() =>
      // dependency without injected constructor
      const PackageModelMapper();
}
