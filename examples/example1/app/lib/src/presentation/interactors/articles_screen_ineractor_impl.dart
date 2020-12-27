import 'package:example1/app.dart';
import 'package:example1/src/domain/interactors/articles_screen_ineractor.dart';
import 'package:example1/src/domain/objects/objects.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:jugger/jugger.dart';

class ArticleScreenInteractorImpl implements IArticlesScreenInteractor {
  @inject
  ArticleScreenInteractorImpl({
    required IArticlesRepository articlesRepository,
    required INavigationRouter router,
  })  : _articlesRepository = articlesRepository,
        _router = router;

  final IArticlesRepository _articlesRepository;
  final INavigationRouter _router;

  @override
  Observable<List<Article>> get articles => _articlesRepository.articles;

  @override
  void openDetailArticlesScreen(int articleId) {
    _router.openDetailArticleScreen(articleId);
  }
}
