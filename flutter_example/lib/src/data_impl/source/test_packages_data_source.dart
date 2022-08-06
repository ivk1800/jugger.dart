import 'package:flutter_example/src/app/data/data.dart';
import 'package:jugger/jugger.dart' as j;

class TestPackagesDataSource {
  @j.inject
  const TestPackagesDataSource();

  Future<List<Package>> getPackages() async {
    return <Package>[
      const Package(
        name: 'jugger',
        likes: 2,
        popularity: 57,
        pubPoints: 110,
        shortDescription:
            'Annotations for jugger_generator. This package does nothing without jugger_generator.',
      ),
      const Package(
        name: 'jugger_generator',
        likes: 8,
        popularity: 16,
        pubPoints: 100,
        shortDescription:
            'Compile-time dependency injection for Dart and Flutter. Inspired by inject.dart and Dagger 2.',
      ),
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
