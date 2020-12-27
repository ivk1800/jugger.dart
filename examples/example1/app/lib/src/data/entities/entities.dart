import 'package:flutter/foundation.dart';

class ArticleEntity {
  const ArticleEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.fullDescription,
  });

  final int id;
  final String title;
  final String description;
  final String fullDescription;
}
