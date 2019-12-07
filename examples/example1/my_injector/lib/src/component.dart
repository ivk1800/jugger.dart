import 'package:example1/main.dart';
import 'package:jugger/jugger.dart';
import 'package:example1/app.dart';

@Component(
    modules: [InteractorModule, RepositoryModule, CommonModule],
    dependencies: [AppComponent]
)
abstract class MyComponent {
  void injectArticlesScreen(ArticlesScreenState target);
  void injectDetailArticleScreen(DetailArticleScreenState target);

  Tracker tracker();
}

@componentBuilder
abstract class MyComponentBuilder {

  MyComponentBuilder tracker(Tracker tracker);

  @Named('test')
  MyComponentBuilder tokenTest(String token);

  MyComponentBuilder tokenProd( String token);

  MyComponentBuilder appComponent(AppComponent component);

  MyComponent build();
}

@module
abstract class InteractorModule {
  @bind
  IArticlesScreenInteractor provideArticlesScreenInteractor(ArticleScreenInteractorImpl impl);

  @provide
  @Named('test')
  static IDetailArticleScreenInteractor provideDetailArticleScreenInteractor(
      IArticlesRepository articlesRepository,
      Tracker tracker,
      @Named('test') String token,
      ) {
    return DetailArticleScreenInteractorImpl(
      articlesRepository: articlesRepository,
      tracker: tracker
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

@Component(modules: [AppModule])
abstract class AppComponent {

  Logger logger();
}

@module
abstract class AppModule {
  @provide
  @singleton
  static Logger provideLogger() {
    return Logger();
  }
}