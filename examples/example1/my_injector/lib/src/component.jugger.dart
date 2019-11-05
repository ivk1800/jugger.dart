import 'package:my_injector/src/component.dart' as _i1;
import 'package:jugger/jugger.dart' as _i2;
import 'package:example1/src/data/datasource/assets_articles_data_source.dart'
    as _i3;
import 'package:example1/src/presentation/mappers/detail_article_model_data_mapper.dart'
    as _i4;
import 'package:example1/src/data/mappers/article_entity_data_mapper.dart'
    as _i5;
import 'package:example1/src/presentation/blocs/detail_article_screen_bloc.dart'
    as _i6;
import 'package:example1/src/presentation/interactors/articles_screen_ineractor_impl.dart'
    as _i7;
import 'package:example1/src/presentation/blocs/articles_screen_bloc.dart'
    as _i8;
import 'package:example1/src/presentation/mappers/article_model_data_mapper.dart'
    as _i9;
import 'package:example1/src/presentation/screens/articles_screen.dart' as _i10;
import 'package:example1/src/presentation/screens/detail_article_screen.dart'
    as _i11;

class JuggerMyComponent extends _i1.MyComponent {
  JuggerMyComponent.create() {
    _init();
  }

  _i2.IProvider<dynamic> _assetsArticlesDataSourceProvider;

  _i2.IProvider<dynamic> _iDetailArticleScreenInteractorProvider;

  _i2.IProvider<dynamic> _iArticlesRepositoryProvider;

  _i2.IProvider<dynamic> _detailArticleModelDataMapperProvider;

  _i2.IProvider<dynamic> _articleEntityDataMapperProvider;

  _i2.IProvider<dynamic> _detailArticleBlocProvider;

  _i2.IProvider<dynamic> _articleScreenInteractorImplProvider;

  _i2.IProvider<dynamic> _articlesBlocProvider;

  _i2.IProvider<dynamic> _articleModelDataMapperProvider;

  _i2.IProvider<dynamic> _iNavigationRouterProvider;

  _i2.IProvider<dynamic> _iArticlesScreenInteractorProvider;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _assetsArticlesDataSourceProvider = _i2.SingletonProvider<dynamic>(() {
      return _i3.AssetsArticlesDataSource();
    });
    _iDetailArticleScreenInteractorProvider = _i2.Provider<dynamic>(() {
      return _i1.InteractorModule.provideDetailArticleScreenInteractor(
          _iArticlesRepositoryProvider.get());
    });
    _iArticlesRepositoryProvider = _i2.SingletonProvider<dynamic>(() {
      return _i1.RepositoryModule.provideArticlesRepository(
          _assetsArticlesDataSourceProvider.get(),
          _articleEntityDataMapperProvider.get());
    });
    _detailArticleModelDataMapperProvider = _i2.SingletonProvider<dynamic>(() {
      return _i4.DetailArticleModelDataMapper();
    });
    _articleEntityDataMapperProvider = _i2.SingletonProvider<dynamic>(() {
      return _i5.ArticleEntityDataMapper();
    });
    _detailArticleBlocProvider = _i2.Provider<dynamic>(() {
      return _i6.DetailArticleBloc(
          interactor: _iDetailArticleScreenInteractorProvider.get(),
          articleModelDataMapper: _detailArticleModelDataMapperProvider.get());
    });
    _articleScreenInteractorImplProvider = _i2.Provider<dynamic>(() {
      return _i7.ArticleScreenInteractorImpl(
          articlesRepository: _iArticlesRepositoryProvider.get(),
          router: _iNavigationRouterProvider.get());
    });
    _articlesBlocProvider = _i2.Provider<dynamic>(() {
      return _i8.ArticlesBloc(_iArticlesScreenInteractorProvider.get(),
          _articleModelDataMapperProvider.get());
    });
    _articleModelDataMapperProvider = _i2.SingletonProvider<dynamic>(() {
      return _i9.ArticleModelDataMapper();
    });
    _iNavigationRouterProvider = _i2.SingletonProvider<dynamic>(() {
      return _i1.CommonModule.provideNavigationRouter();
    });
    _iArticlesScreenInteractorProvider = _i2.SingletonProvider<dynamic>(() {
      return _i7.ArticleScreenInteractorImpl(
          articlesRepository: _iArticlesRepositoryProvider.get(),
          router: _iNavigationRouterProvider.get());
    });
  }

  @override
  void injectArticlesScreen(_i10.ArticlesScreenState target) {
    target.bloc = _articlesBlocProvider.get();
  }

  @override
  void injectDetailArticleScreen(_i11.DetailArticleScreenState target) {
    target.bloc = _detailArticleBlocProvider.get();
  }
}
