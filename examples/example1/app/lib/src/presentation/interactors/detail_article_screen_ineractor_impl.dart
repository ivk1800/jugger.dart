import 'package:example1/app.dart';
import 'package:example1/src/domain/objects/objects.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

class DetailArticleScreenInteractorImpl implements IDetailArticleScreenInteractor {

  DetailArticleScreenInteractorImpl({
    @required IArticlesRepository articlesRepository,
  }): _articlesRepository = articlesRepository;

  final IArticlesRepository _articlesRepository;

  @override
  Observable<DetailArticle> getDetailArticle(int id) {
    return _articlesRepository.getDetailArticle(id);
  }
}