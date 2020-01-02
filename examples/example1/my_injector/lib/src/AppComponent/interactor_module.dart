import 'package:example1/app.dart';
import 'package:jugger/jugger.dart';

@module
abstract class InteractorModule {
  @bind
  IArticlesScreenInteractor provideArticlesScreenInteractor(
      ArticleScreenInteractorImpl impl);

  @provide
  static IDetailArticleScreenInteractor provideDetailArticleScreenInteractor(
    IArticlesRepository articlesRepository,
    Tracker tracker,
  ) {
    return DetailArticleScreenInteractorImpl(
        articlesRepository: articlesRepository, tracker: tracker);
  }
}
