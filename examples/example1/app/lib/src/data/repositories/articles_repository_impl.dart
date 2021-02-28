import 'package:example1/src/data/datasource/assets_articles_data_source.dart';
import 'package:example1/src/data/entities/entities.dart';
import 'package:example1/src/domain/objects/objects.dart';
import 'package:example1/src/domain/repositories/articles_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../../app.dart';

class ArticlesRepositoryImpl implements IArticlesRepository {
  ArticlesRepositoryImpl({
    required AssetsArticlesDataSource dataSource,
    required ArticleEntityDataMapper articlesEntityDataMapper,
  })   : _dataSource = dataSource,
        _articlesEntityDataMapper = articlesEntityDataMapper;

  final AssetsArticlesDataSource _dataSource;
  final ArticleEntityDataMapper _articlesEntityDataMapper;

  List<ArticleEntity> _cachedArticles;

  @override
  Observable<List<Article>> get articles {
    if (_cachedArticles != null) {
      return Observable<List<ArticleEntity>>.just(_cachedArticles)
          .map(_articlesEntityDataMapper.transformList);
    }
    return _dataSource.articles.doOnData((List<ArticleEntity> data) {
      _cachedArticles = data;
    }).map(_articlesEntityDataMapper.transformList);
  }

  @override
  Observable<DetailArticle> getDetailArticle(int id) {
    if (_cachedArticles != null) {
      return Observable<ArticleEntity>.just(
              _cachedArticles.firstWhere((ArticleEntity a) => a.id == id))
          .map((ArticleEntity a) {
        return DetailArticle(
            id: a.id, description: a.fullDescription, title: a.title);
      });
    }
    return Observable<DetailArticle>.error('not found');
  }
}
