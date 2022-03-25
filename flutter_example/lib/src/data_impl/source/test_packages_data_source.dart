import 'package:flutter_example/src/app/data/data.dart';
import 'package:jugger/jugger.dart' as j;

class TestPackagesDataSource {
  @j.inject
  const TestPackagesDataSource();

  Future<List<Package>> getPackages() async {
    return <Package>[
      const Package(
        name: 'http',
        likes: 4336,
        popularity: 100,
        pubPoints: 130,
        shortDescription:
            'A composable, multi-platform, Future-based API for HTTP requests.',
      ),
      const Package(
        name: 'url_launcher',
        likes: 4098,
        popularity: 100,
        pubPoints: 130,
        shortDescription:
            'Flutter plugin for launching a URL. Supports web, phone, SMS, and email schemes.',
      ),
      const Package(
        name: 'provider',
        likes: 6278,
        popularity: 100,
        pubPoints: 130,
        shortDescription:
            'A wrapper around InheritedWidget to make them easier to use and more reusable.',
      ),
      const Package(
        name: 'image_picker',
        likes: 3551,
        popularity: 100,
        pubPoints: 130,
        shortDescription:
            'Flutter plugin for selecting images from the Android and iOS image library, and taking new pictures with the camera.',
      ),
    ];
  }
}
