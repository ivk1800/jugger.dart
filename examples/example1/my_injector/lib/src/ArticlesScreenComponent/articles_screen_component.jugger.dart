// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
import 'package:example1/src/presentation/blocs/articles_screen_bloc.dart'
    as _i1;
import 'package:example1/src/presentation/mappers/article_model_data_mapper.dart'
    as _i2;
import 'package:my_injector/src/ArticlesScreenComponent/articles_screen_component.dart'
    as _i3;
import 'package:my_injector/src/AppComponent/app_component.dart' as _i4;
import 'package:jugger/jugger.dart' as _i5;
import 'package:example1/src/presentation/screens/articles_screen.dart' as _i6;

class JuggerArticlesScreenComponentBuilder
    implements _i3.ArticlesScreenComponentBuilder {
  _i4.AppComponent _appComponent;

  @override
  _i3.ArticlesScreenComponentBuilder appComponent(_i4.AppComponent component) {
    _appComponent = component;
    return this;
  }

  @override
  _i3.ArticlesScreenComponent build() {
    assert(_appComponent != null);
    ;
    return JuggerArticlesScreenComponent._create(_appComponent);
  }
}

class JuggerArticlesScreenComponent implements _i3.ArticlesScreenComponent {
  JuggerArticlesScreenComponent._create(this._appComponent) {
    _init();
  }

  _i5.IProvider<_i1.ArticlesBloc> _articlesBlocProvider;

  _i5.IProvider<_i2.ArticleModelDataMapper> _articleModelDataMapperProvider;

  final _i4.AppComponent _appComponent;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _articlesBlocProvider = _i5.Provider<_i1.ArticlesBloc>(() {
      return _i1.ArticlesBloc(_appComponent.articlesScreenInteractor(),
          _articleModelDataMapperProvider.get());
    });
    _articleModelDataMapperProvider =
        _i5.SingletonProvider<_i2.ArticleModelDataMapper>(() {
      return _i2.ArticleModelDataMapper();
    });
  }

  @override
  void inject(_i6.ArticlesScreenState target) {
    target.bloc = _articlesBlocProvider.get();
    target.tracker = _appComponent.tracker();
  }
}
