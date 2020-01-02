import 'dart:convert';

import 'package:example1/src/data/entities/entities.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jugger/jugger.dart';

class AssetsArticlesDataSource {
  @inject
  @singleton
  AssetsArticlesDataSource();

  Observable<List<ArticleEntity>> get articles {
    return Observable<String>.fromFuture(
            rootBundle.loadString('assets/articles.json'))
        .map((String json) {
      final List<dynamic> jsonList = jsonDecode(json);
      // ignore: avoid_as
      return jsonList
          .map((dynamic v) => v as Map<String, dynamic>)
          .map((Map<String, dynamic> j) {
        return ArticleEntity(
          id: j['id'],
          title: j['title'],
          description: j['description'],
          fullDescription: j['full_description'],
        );
      }).toList();
    }).delay(Duration(seconds: 4));
  }
}
