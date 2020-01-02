// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
import 'package:example1/src/domain/interactors/detail_article_screen_ineractor.dart'
    as _i1;
import 'package:example1/src/core/logger.dart' as _i2;
import 'package:example1/src/data/datasource/assets_articles_data_source.dart'
    as _i3;
import 'package:example1/src/domain/repositories/articles_repository.dart'
    as _i4;
import 'package:example1/src/data/mappers/article_entity_data_mapper.dart'
    as _i5;
import 'package:example1/src/domain/interactors/articles_screen_ineractor.dart'
    as _i6;
import 'package:example1/src/core/navigation_router.dart' as _i7;
import 'package:example1/src/core/tracker.dart' as _i8;
import 'package:my_injector/src/AppComponent/app_component.dart' as _i9;
import 'package:jugger/jugger.dart' as _i10;
import 'package:my_injector/src/AppComponent/interactor_module.dart' as _i11;
import 'package:my_injector/src/AppComponent/app_module.dart' as _i12;
import 'package:my_injector/src/AppComponent/repository_module.dart' as _i13;
import 'package:example1/src/presentation/interactors/articles_screen_ineractor_impl.dart'
    as _i14;

class JuggerAppComponent implements _i9.AppComponent {
  JuggerAppComponent.create() {
    _init();
  }

  _i10.IProvider<_i1.IDetailArticleScreenInteractor>
      _iDetailArticleScreenInteractorProvider;

  _i10.IProvider<_i2.Logger> _loggerProvider;

  _i10.IProvider<_i3.AssetsArticlesDataSource>
      _assetsArticlesDataSourceProvider;

  _i10.IProvider<_i4.IArticlesRepository> _iArticlesRepositoryProvider;

  _i10.IProvider<_i5.ArticleEntityDataMapper> _articleEntityDataMapperProvider;

  _i10.IProvider<_i6.IArticlesScreenInteractor>
      _iArticlesScreenInteractorProvider;

  _i10.IProvider<_i7.INavigationRouter> _iNavigationRouterProvider;

  _i10.IProvider<_i8.Tracker> _trackerProvider;

  @override
  _i2.Logger logger() {
    return _loggerProvider.get();
  }

  @override
  _i8.Tracker tracker() {
    return _trackerProvider.get();
  }

  @override
  _i6.IArticlesScreenInteractor articlesScreenInteractor() {
    return _iArticlesScreenInteractorProvider.get();
  }

  @override
  _i1.IDetailArticleScreenInteractor detailArticleScreenInteractor() {
    return _iDetailArticleScreenInteractorProvider.get();
  }

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _iDetailArticleScreenInteractorProvider =
        _i10.Provider<_i1.IDetailArticleScreenInteractor>(() {
      return _i11.InteractorModule.provideDetailArticleScreenInteractor(
          _iArticlesRepositoryProvider.get(), _trackerProvider.get());
    });
    _loggerProvider = _i10.SingletonProvider<_i2.Logger>(() {
      return _i12.AppModule.provideLogger();
    });
    _assetsArticlesDataSourceProvider =
        _i10.SingletonProvider<_i3.AssetsArticlesDataSource>(() {
      return _i3.AssetsArticlesDataSource();
    });
    _iArticlesRepositoryProvider =
        _i10.SingletonProvider<_i4.IArticlesRepository>(() {
      return _i13.RepositoryModule.provideArticlesRepository(
          _assetsArticlesDataSourceProvider.get(),
          _articleEntityDataMapperProvider.get());
    });
    _articleEntityDataMapperProvider =
        _i10.SingletonProvider<_i5.ArticleEntityDataMapper>(() {
      return _i5.ArticleEntityDataMapper();
    });
    _iArticlesScreenInteractorProvider =
        _i10.Provider<_i6.IArticlesScreenInteractor>(() {
      return _i14.ArticleScreenInteractorImpl(
          articlesRepository: _iArticlesRepositoryProvider.get(),
          router: _iNavigationRouterProvider.get());
    });
    _iNavigationRouterProvider =
        _i10.SingletonProvider<_i7.INavigationRouter>(() {
      return _i12.AppModule.provideNavigationRouter();
    });
    _trackerProvider = _i10.SingletonProvider<_i8.Tracker>(() {
      return _i12.AppModule.provideTracker();
    });
  }
}
