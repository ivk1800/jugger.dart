import 'package:my_injector/src/component.dart' as _i1;
import 'package:meta/meta.dart' as _i2;
import 'package:jugger/jugger.dart' as _i3;
import 'package:example1/src/data/datasource/assets_articles_data_source.dart'
    as _i4;
import 'package:example1/src/presentation/mappers/detail_article_model_data_mapper.dart'
    as _i5;
import 'package:example1/src/data/mappers/article_entity_data_mapper.dart'
    as _i6;
import 'package:example1/src/presentation/blocs/detail_article_screen_bloc.dart'
    as _i7;
import 'package:example1/src/presentation/blocs/articles_screen_bloc.dart'
    as _i8;
import 'package:example1/src/presentation/mappers/article_model_data_mapper.dart'
    as _i9;
import 'package:example1/src/presentation/screens/articles_screen.dart' as _i10;
import 'package:example1/src/presentation/screens/detail_article_screen.dart'
    as _i11;

class JuggerMyComponent extends _i1.MyComponent {
  JuggerMyComponent.create(
      {@_i2.required _i1.InteractorModule interactorModule,
      @_i2.required _i1.RepositoryModule repositoryModule,
      @_i2.required _i1.CommonModule commonModule})
      : _interactorModule = interactorModule,
        _repositoryModule = repositoryModule,
        _commonModule = commonModule {
    _init();
  }

  _i3.IProvider<dynamic> _assetsArticlesDataSourceProvider;

  _i3.IProvider<dynamic> _iDetailArticleScreenInteractorProvider;

  _i3.IProvider<dynamic> _iArticlesRepositoryProvider;

  _i3.IProvider<dynamic> _detailArticleModelDataMapperProvider;

  _i3.IProvider<dynamic> _articleEntityDataMapperProvider;

  _i3.IProvider<dynamic> _detailArticleBlocProvider;

  _i3.IProvider<dynamic> _articlesBlocProvider;

  _i3.IProvider<dynamic> _articleModelDataMapperProvider;

  _i3.IProvider<dynamic> _iNavigationRouterProvider;

  _i3.IProvider<dynamic> _iArticlesScreenInteractorProvider;

  final _i1.InteractorModule _interactorModule;

  final _i1.RepositoryModule _repositoryModule;

  final _i1.CommonModule _commonModule;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _assetsArticlesDataSourceProvider = _i3.SingletonProvider<dynamic>(() {
      return _i4.AssetsArticlesDataSource();
    });
    _iDetailArticleScreenInteractorProvider = _i3.Provider<dynamic>(() {
      return _interactorModule.provideDetailArticleScreenInteractor(
          _iArticlesRepositoryProvider.get());
    });
    _iArticlesRepositoryProvider = _i3.SingletonProvider<dynamic>(() {
      return _repositoryModule.provideArticlesRepository(
          _assetsArticlesDataSourceProvider.get(),
          _articleEntityDataMapperProvider.get());
    });
    _detailArticleModelDataMapperProvider = _i3.SingletonProvider<dynamic>(() {
      return _i5.DetailArticleModelDataMapper();
    });
    _articleEntityDataMapperProvider = _i3.SingletonProvider<dynamic>(() {
      return _i6.ArticleEntityDataMapper();
    });
    _detailArticleBlocProvider = _i3.Provider<dynamic>(() {
      return _i7.DetailArticleBloc(
          _iDetailArticleScreenInteractorProvider.get(),
          _detailArticleModelDataMapperProvider.get());
    });
    _articlesBlocProvider = _i3.Provider<dynamic>(() {
      return _i8.ArticlesBloc(_iArticlesScreenInteractorProvider.get(),
          _articleModelDataMapperProvider.get());
    });
    _articleModelDataMapperProvider = _i3.SingletonProvider<dynamic>(() {
      return _i9.ArticleModelDataMapper();
    });
    _iNavigationRouterProvider = _i3.SingletonProvider<dynamic>(() {
      return _commonModule.provideNavigationRouter();
    });
    _iArticlesScreenInteractorProvider = _i3.Provider<dynamic>(() {
      return _interactorModule.provideArticlesScreenInteractor(
          _iArticlesRepositoryProvider.get(), _iNavigationRouterProvider.get());
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
