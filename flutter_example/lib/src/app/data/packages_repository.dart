import 'package.dart';

abstract class IPackagesRepository {
  Future<List<Package>> getPackages();
}
