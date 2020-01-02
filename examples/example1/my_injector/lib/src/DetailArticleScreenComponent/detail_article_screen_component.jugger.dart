// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
import 'package:my_injector/src/DetailArticleScreenComponent/detail_article_screen_component.dart'
    as _i1;
import 'package:my_injector/src/AppComponent/app_component.dart' as _i2;
import 'package:example1/src/presentation/screens/detail_article_screen.dart'
    as _i3;
import 'package:jugger/jugger.dart' as _i4;
import 'package:my_injector/src/DetailArticleScreenComponent/detail_article_screen_module.dart'
    as _i5;
import 'package:example1/src/presentation/mappers/detail_article_model_data_mapper.dart'
    as _i6;
import 'package:example1/src/presentation/blocs/detail_article_screen_bloc.dart'
    as _i7;

class JuggerDetailArticleScreenComponentBuilder
    implements _i1.DetailArticleScreenComponentBuilder {
  _i2.AppComponent _appComponent;

  _i3.DetailArticleScreenState _detailArticleScreenState;

  @override
  _i1.DetailArticleScreenComponentBuilder appComponent(
      _i2.AppComponent component) {
    _appComponent = component;
    return this;
  }

  @override
  _i1.DetailArticleScreenComponentBuilder screen(
      _i3.DetailArticleScreenState screen) {
    _detailArticleScreenState = screen;
    return this;
  }

  @override
  _i1.DetailArticleScreenComponent build() {
    assert(_appComponent != null);
    assert(_detailArticleScreenState != null);
    ;
    return JuggerDetailArticleScreenComponent._create(
        _appComponent, _detailArticleScreenState);
  }
}

class JuggerDetailArticleScreenComponent
    implements _i1.DetailArticleScreenComponent {
  JuggerDetailArticleScreenComponent._create(
      this._appComponent, this._detailArticleScreenState) {
    _init();
  }

  _i4.IProvider<dynamic> _intProvider;

  _i4.IProvider<dynamic> _detailArticleModelDataMapperProvider;

  _i4.IProvider<dynamic> _detailArticleBlocProvider;

  final _i2.AppComponent _appComponent;

  final _i3.DetailArticleScreenState _detailArticleScreenState;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _intProvider = _i4.Provider<dynamic>(() {
      return _i5.DetailArticleScreenModule.provideArticleId(
          _detailArticleScreenState);
    });
    _detailArticleModelDataMapperProvider = _i4.SingletonProvider<dynamic>(() {
      return _i6.DetailArticleModelDataMapper();
    });
    _detailArticleBlocProvider = _i4.Provider<dynamic>(() {
      return _i7.DetailArticleBloc(
          interactor: _appComponent.detailArticleScreenInteractor(),
          articleModelDataMapper: _detailArticleModelDataMapperProvider.get(),
          articleId: _intProvider.get());
    });
  }

  @override
  void inject(_i3.DetailArticleScreenState target) {
    target.bloc = _detailArticleBlocProvider.get();
  }
}
