import 'package:jugger/jugger.dart';
import 'package:example1/app.dart';

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