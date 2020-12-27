import 'package:flutter/foundation.dart';

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}

class DetailArticle {
  const DetailArticle({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}
