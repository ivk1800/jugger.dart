import 'package:flutter_example/src/app/data/data.dart';
import 'package:jugger/jugger.dart' as j;

class BrokenPackagesRepository implements IPackagesRepository {
  @j.inject
  const BrokenPackagesRepository();

  @override
  Future<List<Package>> getPackages() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    throw Exception('Broken repository');
  }
}
