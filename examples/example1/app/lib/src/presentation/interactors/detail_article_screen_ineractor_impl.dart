import 'package:example1/app.dart';
import 'package:example1/src/domain/objects/objects.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

class DetailArticleScreenInteractorImpl
    implements IDetailArticleScreenInteractor {
  DetailArticleScreenInteractorImpl({
    @required IArticlesRepository articlesRepository,
    @required Tracker tracker,
  })  : _articlesRepository = articlesRepository,
        _tracker = tracker;

  final IArticlesRepository _articlesRepository;
  final Tracker _tracker;

  @override
  Observable<DetailArticle> getDetailArticle(int id) {
    return _articlesRepository.getDetailArticle(id);
  }
}