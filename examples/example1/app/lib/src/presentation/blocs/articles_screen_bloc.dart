import 'package:example1/src/domain/interactors/articles_screen_ineractor.dart';
import 'package:example1/src/presentation/mappers/article_model_data_mapper.dart';
import 'package:example1/src/presentation/models/models.dart';
import 'package:rxdart/rxdart.dart';
import 'package:jugger/jugger.dart';
import 'base_bloc.dart';

class ArticlesBloc extends BaseBloc {
  @inject
  ArticlesBloc(IArticlesScreenInteractor interactor,
      ArticleModelDataMapper articleModelDataMapper)
      : _interactor = interactor,
        _articleModelDataMapper = articleModelDataMapper;

  final IArticlesScreenInteractor _interactor;
  final ArticleModelDataMapper _articleModelDataMapper;

  Observable<List<ArticleModel>> get articles =>
      _interactor.articles.map(_articleModelDataMapper.transformList);

  void articleClicked(ArticleModel article) {
    _interactor.openDetailArticlesScreen(article.id);
  }
}
