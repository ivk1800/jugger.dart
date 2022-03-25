import 'package:flutter_example/src/app/data/data.dart';
import 'package:jugger/jugger.dart' as j;

import 'source/test_packages_data_source.dart';

class PackagesRepositoryImpl implements IPackagesRepository {
  @j.inject
  const PackagesRepositoryImpl({
    required TestPackagesDataSource dataSource,
  }) : _dataSource = dataSource;

  final TestPackagesDataSource _dataSource;

  @override
  Future<List<Package>> getPackages() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return _dataSource.getPackages();
  }
}
