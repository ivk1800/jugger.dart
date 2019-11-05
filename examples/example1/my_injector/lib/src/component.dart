import 'package:example1/main.dart';
import 'package:jugger/jugger.dart';
import 'package:example1/app.dart';

@Component([InteractorModule, RepositoryModule, CommonModule])
abstract class MyComponent {
  void injectArticlesScreen(ArticlesScreenState target);
  void injectDetailArticleScreen(DetailArticleScreenState target);
}

@module
abstract class InteractorModule {
  @bind
  IArticlesScreenInteractor provideArticlesScreenInteractor(ArticleScreenInteractorImpl impl);

  @provide
  static IDetailArticleScreenInteractor provideDetailArticleScreenInteractor(
      IArticlesRepository articlesRepository,
      ) {
    return DetailArticleScreenInteractorImpl(
      articlesRepository: articlesRepository,
    );
  }
}

@module
abstract class RepositoryModule {
  @provide
  @singleton
  static IArticlesRepository provideArticlesRepository(AssetsArticlesDataSource dataSource,
      ArticleEntityDataMapper articlesEntityDataMapper) {
    return ArticlesRepositoryImpl(
        dataSource: dataSource, articlesEntityDataMapper: articlesEntityDataMapper);
  }
}

@module
abstract class CommonModule {
  @singleton
  @provide
  static INavigationRouter provideNavigationRouter() {
    return NavigationRouteImpl(
      navigationKey: MyApp.navigatorKey,
    );
  }
}
