import 'package:flutter_example/src/app/data/data.dart';
import 'package:flutter_example/src/screen/packages_list/package_model.dart';

class PackageModelMapper {
  const PackageModelMapper();

  List<PackageModel> mapToPackageModels(List<Package> packages) {
    return packages
        .map(
          (Package e) => PackageModel(
            name: e.name,
            shortDescription: e.shortDescription,
            likes: e.likes,
            pubPoints: e.pubPoints,
            popularity: e.popularity,
          ),
        )
        .toList(growable: false);
  }
}
