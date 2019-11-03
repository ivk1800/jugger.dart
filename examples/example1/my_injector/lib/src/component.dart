import 'package:flutter/widgets.dart';
import 'package:jugger/jugger.dart';
import 'package:example1/app.dart';

@Component([InteractorModule, RepositoryModule, CommonModule])
abstract class MyComponent {
  void injectArticlesScreen(ArticlesScreenState target);
  void injectDetailArticleScreen(DetailArticleScreenState target);
}

@module
class InteractorModule {
  @provide
  IArticlesScreenInteractor provideArticlesScreenInteractor(
    IArticlesRepository articlesRepository,
    INavigationRouter router,
  ) {
    return ArticleScreenInteractorImpl(
      articlesRepository: articlesRepository,
      router: router,
    );
  }

  @provide
  IDetailArticleScreenInteractor provideDetailArticleScreenInteractor(
      IArticlesRepository articlesRepository,
      ) {
    return DetailArticleScreenInteractorImpl(
      articlesRepository: articlesRepository,
    );
  }
}

@module
class RepositoryModule {
  @provide
  @singleton
  IArticlesRepository provideArticlesRepository(AssetsArticlesDataSource dataSource,
      ArticleEntityDataMapper articlesEntityDataMapper) {
    return ArticlesRepositoryImpl(
        dataSource: dataSource, articlesEntityDataMapper: articlesEntityDataMapper);
  }
}

@module
class CommonModule {
  CommonModule({@required GlobalKey<NavigatorState> navigationKey})
      : _navigationKey = navigationKey;

  final GlobalKey<NavigatorState> _navigationKey;

  @singleton
  @provide
  INavigationRouter provideNavigationRouter() {
    return NavigationRouteImpl(
      navigationKey: _navigationKey,
    );
  }
}
