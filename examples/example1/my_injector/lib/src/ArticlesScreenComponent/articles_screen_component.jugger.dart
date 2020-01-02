// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
import 'package:my_injector/src/ArticlesScreenComponent/articles_screen_component.dart'
    as _i1;
import 'package:my_injector/src/AppComponent/app_component.dart' as _i2;
import 'package:jugger/jugger.dart' as _i3;
import 'package:example1/src/presentation/blocs/articles_screen_bloc.dart'
    as _i4;
import 'package:example1/src/presentation/mappers/article_model_data_mapper.dart'
    as _i5;
import 'package:example1/src/presentation/screens/articles_screen.dart' as _i6;

class JuggerArticlesScreenComponentBuilder
    implements _i1.ArticlesScreenComponentBuilder {
  _i2.AppComponent _appComponent;

  @override
  _i1.ArticlesScreenComponentBuilder appComponent(_i2.AppComponent component) {
    _appComponent = component;
    return this;
  }

  @override
  _i1.ArticlesScreenComponent build() {
    assert(_appComponent != null);
    ;
    return JuggerArticlesScreenComponent._create(_appComponent);
  }
}

class JuggerArticlesScreenComponent implements _i1.ArticlesScreenComponent {
  JuggerArticlesScreenComponent._create(this._appComponent) {
    _init();
  }

  _i3.IProvider<dynamic> _articlesBlocProvider;

  _i3.IProvider<dynamic> _articleModelDataMapperProvider;

  final _i2.AppComponent _appComponent;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _articlesBlocProvider = _i3.Provider<dynamic>(() {
      return _i4.ArticlesBloc(_appComponent.articlesScreenInteractor(),
          _articleModelDataMapperProvider.get());
    });
    _articleModelDataMapperProvider = _i3.SingletonProvider<dynamic>(() {
      return _i5.ArticleModelDataMapper();
    });
  }

  @override
  void inject(_i6.ArticlesScreenState target) {
    target.bloc = _articlesBlocProvider.get();
    target.tracker = _appComponent.tracker();
  }
}
