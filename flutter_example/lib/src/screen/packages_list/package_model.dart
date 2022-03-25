import 'package:meta/meta.dart';

@immutable
class PackageModel {
  const PackageModel({
    required this.name,
    required this.shortDescription,
    required this.likes,
    required this.pubPoints,
    required this.popularity,
  });

  final String name;
  final String shortDescription;
  final int likes;
  final int pubPoints;
  final int popularity;
}
