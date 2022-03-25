import 'package:flutter_example/src/app/data/data.dart';
import 'package:flutter_example/src/data_impl/data_impl.dart';
import 'package:jugger/jugger.dart' as j;

@j.module
abstract class DataModule {
  @j.binds
  IPackagesRepository bindsPackagesRepository(PackagesRepositoryImpl impl);
}
