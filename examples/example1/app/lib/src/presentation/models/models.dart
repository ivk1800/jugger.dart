import 'package:flutter/foundation.dart';

class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}

class DetailArticleModel {
  const DetailArticleModel({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}
