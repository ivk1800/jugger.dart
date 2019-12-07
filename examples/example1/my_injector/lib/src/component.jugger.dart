import 'package:my_injector/src/component.dart' as _i1;
import 'package:example1/src/core/tracker.dart' as _i2;
import 'package:jugger/jugger.dart' as _i3;
import 'package:example1/src/data/datasource/assets_articles_data_source.dart'
    as _i4;
import 'package:example1/src/presentation/mappers/detail_article_model_data_mapper.dart'
    as _i5;
import 'package:example1/src/presentation/blocs/detail_article_screen_bloc.dart'
    as _i6;
import 'package:example1/src/presentation/interactors/articles_screen_ineractor_impl.dart'
    as _i7;
import 'package:example1/src/data/mappers/article_entity_data_mapper.dart'
    as _i8;
import 'package:example1/src/presentation/mappers/article_model_data_mapper.dart'
    as _i9;
import 'package:example1/src/presentation/blocs/articles_screen_bloc.dart'
    as _i10;
import 'package:example1/src/presentation/screens/articles_screen.dart' as _i11;
import 'package:example1/src/presentation/screens/detail_article_screen.dart'
    as _i12;

class JuggerMyComponentBuilder implements _i1.MyComponentBuilder {
  _i2.Tracker _tracker;

  String _string;

  @override
  _i1.MyComponentBuilder tracker(_i2.Tracker tracker) {
    _tracker = tracker;
    return this;
  }

  @override
  _i1.MyComponentBuilder token(String token) {
    _string = token;
    return this;
  }

  @override
  _i1.MyComponent build() {
    assert(_tracker != null);
    assert(_string != null);
    ;
    return JuggerMyComponent._create(_tracker, _string);
  }
}

class JuggerMyComponent implements _i1.MyComponent {
  JuggerMyComponent._create(this._tracker, this._string) {
    _init();
  }

  _i3.IProvider<dynamic> _assetsArticlesDataSourceProvider;

  _i3.IProvider<dynamic> _iDetailArticleScreenInteractorProvider;

  _i3.IProvider<dynamic> _detailArticleModelDataMapperProvider;

  _i3.IProvider<dynamic> _detailArticleBlocProvider;

  _i3.IProvider<dynamic> _articleScreenInteractorImplProvider;

  _i3.IProvider<dynamic> _iArticlesScreenInteractorProvider;

  _i3.IProvider<dynamic> _iArticlesRepositoryProvider;

  _i3.IProvider<dynamic> _articleEntityDataMapperProvider;

  _i3.IProvider<dynamic> _articleModelDataMapperProvider;

  _i3.IProvider<dynamic> _articlesBlocProvider;

  _i3.IProvider<dynamic> _iNavigationRouterProvider;

  final _i2.Tracker _tracker;

  final String _string;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _assetsArticlesDataSourceProvider = _i3.SingletonProvider<dynamic>(() {
      return _i4.AssetsArticlesDataSource();
    });
    _iDetailArticleScreenInteractorProvider = _i3.Provider<dynamic>(() {
      return _i1.InteractorModule.provideDetailArticleScreenInteractor(
          _iArticlesRepositoryProvider.get(), _tracker);
    });
    _detailArticleModelDataMapperProvider = _i3.SingletonProvider<dynamic>(() {
      return _i5.DetailArticleModelDataMapper();
    });
    _detailArticleBlocProvider = _i3.Provider<dynamic>(() {
      return _i6.DetailArticleBloc(
          interactor: _iDetailArticleScreenInteractorProvider.get(),
          articleModelDataMapper: _detailArticleModelDataMapperProvider.get());
    });
    _articleScreenInteractorImplProvider = _i3.Provider<dynamic>(() {
      return _i7.ArticleScreenInteractorImpl(
          articlesRepository: _iArticlesRepositoryProvider.get(),
          router: _iNavigationRouterProvider.get());
    });
    _iArticlesScreenInteractorProvider = _i3.Provider<dynamic>(() {
      return _i7.ArticleScreenInteractorImpl(
          articlesRepository: _iArticlesRepositoryProvider.get(),
          router: _iNavigationRouterProvider.get());
    });
    _iArticlesRepositoryProvider = _i3.SingletonProvider<dynamic>(() {
      return _i1.RepositoryModule.provideArticlesRepository(
          _assetsArticlesDataSourceProvider.get(),
          _articleEntityDataMapperProvider.get());
    });
    _articleEntityDataMapperProvider = _i3.SingletonProvider<dynamic>(() {
      return _i8.ArticleEntityDataMapper();
    });
    _articleModelDataMapperProvider = _i3.SingletonProvider<dynamic>(() {
      return _i9.ArticleModelDataMapper();
    });
    _articlesBlocProvider = _i3.Provider<dynamic>(() {
      return _i10.ArticlesBloc(_iArticlesScreenInteractorProvider.get(),
          _articleModelDataMapperProvider.get());
    });
    _iNavigationRouterProvider = _i3.SingletonProvider<dynamic>(() {
      return _i1.CommonModule.provideNavigationRouter();
    });
  }

  @override
  void injectArticlesScreen(_i11.ArticlesScreenState target) {
    target.bloc = _articlesBlocProvider.get();
    target.tracker = _tracker;
    target.token = _string;
  }

  @override
  void injectDetailArticleScreen(_i12.DetailArticleScreenState target) {
    target.bloc = _detailArticleBlocProvider.get();
  }
}

class JuggerAppComponent implements _i1.AppComponent {
  JuggerAppComponent.create() {
    _init();
  }

  _i3.IProvider<dynamic> _loggerProvider;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _loggerProvider = _i3.SingletonProvider<dynamic>(() {
      return _i1.AppModule.provideLogger();
    });
  }
}
