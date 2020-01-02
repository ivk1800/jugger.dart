// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
import 'package:my_injector/src/AppComponent/app_component.dart' as _i1;
import 'package:jugger/jugger.dart' as _i2;
import 'package:example1/src/core/logger.dart' as _i3;
import 'package:example1/src/core/tracker.dart' as _i4;
import 'package:example1/src/domain/interactors/articles_screen_ineractor.dart'
    as _i5;
import 'package:example1/src/domain/interactors/detail_article_screen_ineractor.dart'
    as _i6;
import 'package:my_injector/src/AppComponent/interactor_module.dart' as _i7;
import 'package:my_injector/src/AppComponent/app_module.dart' as _i8;
import 'package:example1/src/data/datasource/assets_articles_data_source.dart'
    as _i9;
import 'package:my_injector/src/AppComponent/repository_module.dart' as _i10;
import 'package:example1/src/data/mappers/article_entity_data_mapper.dart'
    as _i11;
import 'package:example1/src/presentation/interactors/articles_screen_ineractor_impl.dart'
    as _i12;

class JuggerAppComponent implements _i1.AppComponent {
  JuggerAppComponent.create() {
    _init();
  }

  _i2.IProvider<dynamic> _iDetailArticleScreenInteractorProvider;

  _i2.IProvider<dynamic> _loggerProvider;

  _i2.IProvider<dynamic> _assetsArticlesDataSourceProvider;

  _i2.IProvider<dynamic> _iArticlesRepositoryProvider;

  _i2.IProvider<dynamic> _articleEntityDataMapperProvider;

  _i2.IProvider<dynamic> _iArticlesScreenInteractorProvider;

  _i2.IProvider<dynamic> _iNavigationRouterProvider;

  _i2.IProvider<dynamic> _trackerProvider;

  @override
  _i3.Logger logger() {
    return _loggerProvider.get();
  }

  @override
  _i4.Tracker tracker() {
    return _trackerProvider.get();
  }

  @override
  _i5.IArticlesScreenInteractor articlesScreenInteractor() {
    return _iArticlesScreenInteractorProvider.get();
  }

  @override
  _i6.IDetailArticleScreenInteractor detailArticleScreenInteractor() {
    return _iDetailArticleScreenInteractorProvider.get();
  }

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _iDetailArticleScreenInteractorProvider = _i2.Provider<dynamic>(() {
      return _i7.InteractorModule.provideDetailArticleScreenInteractor(
          _iArticlesRepositoryProvider.get(), _trackerProvider.get());
    });
    _loggerProvider = _i2.SingletonProvider<dynamic>(() {
      return _i8.AppModule.provideLogger();
    });
    _assetsArticlesDataSourceProvider = _i2.SingletonProvider<dynamic>(() {
      return _i9.AssetsArticlesDataSource();
    });
    _iArticlesRepositoryProvider = _i2.SingletonProvider<dynamic>(() {
      return _i10.RepositoryModule.provideArticlesRepository(
          _assetsArticlesDataSourceProvider.get(),
          _articleEntityDataMapperProvider.get());
    });
    _articleEntityDataMapperProvider = _i2.SingletonProvider<dynamic>(() {
      return _i11.ArticleEntityDataMapper();
    });
    _iArticlesScreenInteractorProvider = _i2.Provider<dynamic>(() {
      return _i12.ArticleScreenInteractorImpl(
          articlesRepository: _iArticlesRepositoryProvider.get(),
          router: _iNavigationRouterProvider.get());
    });
    _iNavigationRouterProvider = _i2.SingletonProvider<dynamic>(() {
      return _i8.AppModule.provideNavigationRouter();
    });
    _trackerProvider = _i2.SingletonProvider<dynamic>(() {
      return _i8.AppModule.provideTracker();
    });
  }
}
